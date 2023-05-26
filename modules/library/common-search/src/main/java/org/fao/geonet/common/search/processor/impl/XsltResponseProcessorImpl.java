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
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import javax.servlet.http.HttpSession;
import javax.xml.stream.XMLStreamWriter;
import lombok.Getter;
import lombok.extern.slf4j.Slf4j;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.Serializer.Property;
import org.dom4j.Element;
import org.fao.geonet.common.search.GnMediaType;
import org.fao.geonet.common.search.domain.UserInfo;
import org.fao.geonet.common.xml.XsltUtil;
import org.fao.geonet.domain.Metadata;
import org.fao.geonet.index.model.dcat2.Namespaces;
import org.fao.geonet.index.model.gn.IndexRecordFieldNames;
import org.fao.geonet.repository.MetadataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

@Component("XsltResponseProcessorImpl")
@Slf4j(topic = "org.fao.geonet.common.search.processor")
public class XsltResponseProcessorImpl extends AbstractResponseProcessor {

  @Autowired
  MetadataRepository metadataRepository;

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


  /**
   * Process the search response and return RSS feed.
   */
  public void processResponse(HttpSession httpSession,
      InputStream streamFromServer, OutputStream streamToClient,
      UserInfo userInfo, String bucket, Boolean addPermissions) throws Exception {

    Processor p = new Processor(false);
    Serializer s = p.newSerializer();
    s.setOutputProperty(Property.INDENT, "no");
    s.setOutputStream(streamToClient);
    XMLStreamWriter generator = s.getXMLStreamWriter();

    generator.writeStartDocument("UTF-8", "1.0");
    {
      JsonParser parser = parserForStream(streamFromServer);

      List<Integer> ids = new ArrayList<>();
      new ResponseParser().matchHits(parser, generator, doc -> {
        ids.add(doc
            .get(IndexRecordFieldNames.source)
            .get(IndexRecordFieldNames.id).asInt());
      }, false);

      List<Metadata> records = metadataRepository.findAllById(ids);

      generator.writeStartElement("rdf:RDF");
      generator.writeNamespace("rdf", Namespaces.RDF_URI);
      generator.writeNamespace("dcat", Namespaces.DCAT_URI);
      generator.writeNamespace("dct", Namespaces.DCT_URI);
      generator.writeNamespace("xml", "http://www.w3.org/XML/1998/namespace");

      String xsltCatalogFileName = String.format(
          "xslt/ogcapir/formats/%s/%s-catalog.xsl",
          transformation, transformation);
      try (InputStream xsltFile =
          new ClassPathResource(xsltCatalogFileName).getInputStream()) {
        XsltUtil.transformAndStreamInDocument(
            "<root/>",
            xsltFile,
            generator
        );
      } catch (Exception e) {
        Throwables.throwIfUnchecked(e);
        throw new RuntimeException(e);
      }

      {
        records.forEach(r -> {
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
                generator
            );
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
        });
      }
      generator.writeEndElement();
    }
    generator.writeEndDocument();
    generator.flush();
    generator.close();
  }

  /**  affraid XsltResponseProcessorImpl is NOT reentrant.*/
  @Override
  public void setTransformation(String acceptHeader) {
    transformation = ACCEPT_FORMATTERS.get(acceptHeader);
  }
}
