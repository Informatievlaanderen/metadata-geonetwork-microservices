/**
 * (c) 2020 Open Source Geospatial Foundation - all rights reserved This code is licensed under the
 * GPL 2.0 license, available at the root application directory.
 */

package org.fao.geonet.common.search.processor.impl;

import com.fasterxml.jackson.core.JsonParser;
import com.google.common.base.Throwables;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import javax.servlet.http.HttpSession;
import javax.xml.stream.XMLStreamWriter;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.QName;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.Serializer.Property;
import net.sf.saxon.s9api.XdmMap;
import org.fao.geonet.common.search.GnMediaType;
import org.fao.geonet.common.search.domain.UserInfo;
import org.fao.geonet.common.xml.XsltTransformerFactory;
import org.fao.geonet.common.xml.XsltUtil;
import org.fao.geonet.domain.Metadata;
import org.fao.geonet.domain.Setting;
import org.fao.geonet.index.model.dcat2.Namespaces;
import org.fao.geonet.index.model.gn.IndexRecordFieldNames;
import org.fao.geonet.repository.MetadataRepository;
import org.fao.geonet.repository.SettingRepository;
import org.fao.geonet.utils.Xml;
import org.jdom.Element;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

@Component("XsltResponseProcessorImpl")
@Slf4j(topic = "org.fao.geonet.common.search.processor")
public class XsltResponseProcessorImpl extends AbstractResponseProcessor {

  @Autowired
  MetadataRepository metadataRepository;

  @Autowired
  SettingRepository settingRepository;

  @Getter
  private String transformation = "copy";

  static final Map<String, String>
      ACCEPT_FORMATTERS =
      Map.of(
          GnMediaType.APPLICATION_GN_XML_VALUE, "copy",
          "gn", "copy",
          GnMediaType.APPLICATION_DCAT2_XML_VALUE, "dcat",
          "dcat_ap_vl", "dcat",
          "dcat", "dcat"
      );


  public static final String SYSTEM_CSW_CAPABILITY_RECORD_UUID = "system/csw/capabilityRecordUuid";

  private Optional<Setting> getCatalogDescriptionRecord(String collection) {
    // TODO: If in a collection search for the portal record
    return settingRepository.findById(SYSTEM_CSW_CAPABILITY_RECORD_UUID);
  }

  /**
   * Process the search response and return RSS feed.
   */
  public void processResponse(HttpSession httpSession,
      InputStream streamFromServer, OutputStream streamToClient,
      UserInfo userInfo, String bucket, Boolean addPermissions) throws Exception {

    Processor p = XsltTransformerFactory.getProcessor();
    Serializer s = p.newSerializer();
    s.setOutputProperty(Property.INDENT, "no");
    s.setOutputStream(streamToClient);
    XMLStreamWriter generator = s.getXMLStreamWriter();

    JsonParser parser = parserForStream(streamFromServer);

    List<Integer> ids = new ArrayList<>();
    Map<String, String> recordsUuidAndType = new HashMap<>();
    new ResponseParser().matchHits(parser, generator, doc -> {
      ids.add(doc
          .get(IndexRecordFieldNames.source)
          .get(IndexRecordFieldNames.id).asInt());
      recordsUuidAndType.put(doc.get("_id").asText(),
          doc
              .get(IndexRecordFieldNames.source)
              .get(IndexRecordFieldNames.resourceType).get(0).asText());
    }, false);

    List<Metadata> records = metadataRepository.findAllById(ids);

    boolean streamByRecord = false;


    if (streamByRecord) {
      generator.writeStartDocument("UTF-8", "1.0");
      {
        generator.writeStartElement("rdf:RDF");
        generator.writeNamespace("rdf", Namespaces.RDF_URI);

        String xsltCatalogFileName = String.format(
            "xslt/ogcapir/formats/%s/%s-catalog.xsl",
            transformation, transformation);
        try (InputStream xsltFile =
            new ClassPathResource(xsltCatalogFileName).getInputStream()) {
          XsltUtil.transformAndStreamInDocument(
              "<root/>",
              xsltFile,
              generator,
              Map.of(new QName("recordsUuidAndType"),
                  XdmMap.makeMap(recordsUuidAndType)));
        } catch (Exception e) {
          Throwables.throwIfUnchecked(e);
          throw new RuntimeException(e);
        }

        {
          for (Metadata r : records) {
            String xsltFileName =
                "xml".equals(transformation)
                    ? "xslt/ogcapir/formats/xml/copy.xsl"
                    : String.format(
                        "xslt/ogcapir/formats/%s/%s-%s.xsl",
                        transformation, transformation, r.getDataInfo().getSchemaId());
            try (InputStream xsltFile =
                new ClassPathResource(xsltFileName).getInputStream()) {
              XsltUtil.transformAndStreamInDocument(
                  r.getData(),
                  xsltFile,
                  generator,
                  null);
            } catch (IOException e) {
              // Question of ghost records when no conversion available for a schema
              log.warn(String.format(
                  "XSL conversion not found (record %s is not part of the response). %s.",
                  r.getUuid(),
                  e.getMessage()
              ));
            } catch (Exception e) {
              Throwables.throwIfUnchecked(e);
              throw new RuntimeException(e);
            }
          }
        }
        generator.writeEndElement();
      }
      generator.writeEndDocument();
      generator.flush();
      generator.close();
    } else {
      Element root = new Element("root");
      String collection = "main";
      Optional<Setting> catalogueDescriptionRecordSetting =
          getCatalogDescriptionRecord(collection);
      if (catalogueDescriptionRecordSetting.isPresent()) {
        Metadata serviceMetadata = metadataRepository.findOneByUuid(
            catalogueDescriptionRecordSetting.get().getValue());
        Element catalogueDescriptionRecord = new Element("catalogueDescriptionRecord");
        catalogueDescriptionRecord.addContent(serviceMetadata.getXmlData(false));
        root.addContent(catalogueDescriptionRecord);
      }
      Element allRecords = new Element("records");
      for (Metadata r : records) {
        allRecords.addContent(r.getXmlData(false));
      }
      root.addContent(allRecords);

      String xsltFileName =
          "xml".equals(transformation)
              ? "xslt/ogcapir/formats/xml/copy.xsl"
              : String.format(
                  "xslt/ogcapir/formats/%s/%s-catalog.xsl",
                  transformation, transformation);
      try (InputStream xsltFile =
          new ClassPathResource(xsltFileName).getInputStream()) {
        String response = XsltUtil.transformXmlAsString(
            Xml.getString(root),
            xsltFile,
            Map.of(new QName("recordsUuidAndType"),
                XdmMap.makeMap(recordsUuidAndType)));
        streamToClient.write(response.getBytes(StandardCharsets.UTF_8));
      } catch (IOException e) {
        // Question of ghost records when no conversion available for a schema
        log.warn(String.format(
            "XSL conversion not found. %s.",
            e.getMessage()
        ));
      } catch (Exception e) {
        Throwables.throwIfUnchecked(e);
        throw new RuntimeException(e);
      }
    }
  }

  /**
   * affraid XsltResponseProcessorImpl is NOT reentrant.
   */
  @Override
  public void setTransformation(String acceptHeader) {
    transformation = ACCEPT_FORMATTERS.get(acceptHeader);
  }
}
