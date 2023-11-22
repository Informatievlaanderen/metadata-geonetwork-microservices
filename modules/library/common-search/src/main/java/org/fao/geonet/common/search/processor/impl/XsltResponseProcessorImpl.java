/**
 * (c) 2020 Open Source Geospatial Foundation - all rights reserved This code is licensed under the
 * GPL 2.0 license, available at the root application directory.
 */

package org.fao.geonet.common.search.processor.impl;

import com.fasterxml.jackson.core.JsonParser;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.common.base.Throwables;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import javax.servlet.http.HttpSession;
import javax.xml.stream.XMLStreamWriter;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.Serializer.Property;
import org.apache.commons.lang.StringUtils;
import org.fao.geonet.common.search.GnMediaType;
import org.fao.geonet.common.search.domain.UserInfo;
import org.fao.geonet.common.xml.XsltTransformerFactory;
import org.fao.geonet.common.xml.XsltUtil;
import org.fao.geonet.domain.Metadata;
import org.fao.geonet.domain.Setting;
import org.fao.geonet.index.model.dcat2.Namespaces;
import org.fao.geonet.index.model.gn.IndexRecordFieldNames;
import org.fao.geonet.index.model.gn.IndexRecordFieldNames.CommonField;
import org.fao.geonet.index.model.gn.IndexRecordFieldNames.LinkField;
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

  private Optional<String> getCatalogDescriptionRecord(String collection) {
    // TODO: If in a collection search for the portal record
    Optional<Setting> optionalSetting =
        settingRepository.findById(SYSTEM_CSW_CAPABILITY_RECORD_UUID);
    return optionalSetting.isPresent()
        && StringUtils.isNotEmpty(optionalSetting.get().getValue())
        && !"-1".equals(optionalSetting.get().getValue())
        ? Optional.of(optionalSetting.get().getValue())
        : Optional.empty();
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
    var extras = new Element("extras");

    new ResponseParser().matchHits(
        parser,
        generator,
        doc -> {
          ids.add(doc.get(IndexRecordFieldNames.source).get(IndexRecordFieldNames.id).asInt());
          addExtraInformation(extras, doc);
        },
        false
    );

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
              null);
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
      Optional<String> catalogueDescriptionRecordUuid =
          getCatalogDescriptionRecord(collection);
      if (catalogueDescriptionRecordUuid.isPresent()) {
        Metadata serviceMetadata = metadataRepository.findOneByUuid(
            catalogueDescriptionRecordUuid.get());
        if (serviceMetadata != null) {
          Element catalogueDescriptionRecord = new Element("catalogueDescriptionRecord");
          catalogueDescriptionRecord.addContent(serviceMetadata.getXmlData(false));
          root.addContent(catalogueDescriptionRecord);
        }
      }
      Element allRecords = new Element("records");
      for (Metadata r : records) {
        allRecords.addContent(r.getXmlData(false));
      }

      root.addContent(extras);
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
            null);
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

  private void addExtraInformation(Element extras, ObjectNode doc) {
    var uuid = doc.get(IndexRecordFieldNames.source).get(IndexRecordFieldNames.uuid).asText();

    var extra = new Element("extra");
    extra.setAttribute("uuid", uuid);

    var rdfURI = new Element("rdfResourceURI");
    rdfURI.setText(doc.get(IndexRecordFieldNames.source).get(IndexRecordFieldNames.rdfResourceIdentifier).asText());
    extra.addContent(rdfURI);

    var uriPattern = new Element("uriPattern");
    uriPattern.setText(doc.get(IndexRecordFieldNames.source).get(IndexRecordFieldNames.uriPattern).asText());
    extra.addContent(uriPattern);

    var relations = new Element("relations");
    var docDatasets = doc.get(IndexRecordFieldNames.related).get(IndexRecordFieldNames.datasets);
    if (docDatasets != null) {
      docDatasets.forEach(relDataset -> addExtraRelation(relations, relDataset, "dataset"));
    }
    var docServices = doc.get(IndexRecordFieldNames.related).get(IndexRecordFieldNames.services);
    if (docServices != null) {
      docServices.forEach(relService -> addExtraRelation(relations, relService, "service"));
    }
    extra.addContent(relations);

    extras.addContent(extra);
  }

  private void addExtraRelation(Element relations, JsonNode doc, String type) {
    var rel = new Element(type);

    var sourceUUID = doc.get(IndexRecordFieldNames.source).get("uuid");
    JsonNode docUUID = null;
    if (sourceUUID != null) {
      docUUID = sourceUUID;
    } else if (doc.get("_id") != null) {
      docUUID = doc.get("_id");
    }
    if (docUUID != null) {
      var uuid = new Element("uuid");
      uuid.setText(docUUID.asText());
      rel.addContent(uuid);
    }

    var docURL = doc.get("properties").get("url");
    if (docURL != null) {
      var url = new Element("url");
      url.setText(docURL.asText());
      rel.addContent(url);
    }

    var docRdfURI = doc.get(IndexRecordFieldNames.source)
        .get(IndexRecordFieldNames.rdfResourceIdentifier);
    if (docRdfURI != null) {
      var rdfURI = new Element("rdfResourceURI");
      rdfURI.setText(docRdfURI.asText());
      rel.addContent(rdfURI);
    }

    var docResourceCode = doc.get(IndexRecordFieldNames.source).get(IndexRecordFieldNames.resourceIdentifier);
    if (docResourceCode instanceof ArrayNode && !docResourceCode.isEmpty()) {
      var code = new Element("resourceCode");
      code.setText(docResourceCode.get(0).get("code").asText());
      rel.addContent(code);
    }

    var docTitle = doc.get(IndexRecordFieldNames.source).get(IndexRecordFieldNames.resourceTitle);
    if (docTitle != null) {
      var title = new Element("title");
      title.setText(docTitle.get(CommonField.defaultText).asText());
      rel.addContent(title);
    }

    var docLinks = doc.get(IndexRecordFieldNames.source).get(IndexRecordFieldNames.link);
    if (docLinks instanceof ArrayNode && !docLinks.isEmpty()) {
      docLinks.forEach(docLink -> {
        var link = new Element("link");

        var protocol = new Element("protocol");
        protocol.setText(docLink.get(LinkField.protocol).asText());
        link.addContent(protocol);

        var u = new Element("url");
        u.setText(docLink.get(LinkField.url).get(CommonField.defaultText).asText());
        link.addContent(u);

        rel.addContent(link);
      });
    }

    relations.addContent(rel);
  }
}
