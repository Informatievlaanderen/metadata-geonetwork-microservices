package org.fao.geonet.common.search.processor.impl;

import com.fasterxml.jackson.core.JsonParser;
import com.google.common.base.Throwables;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.ArrayList;
import java.util.List;
import javax.servlet.http.HttpSession;
import javax.xml.stream.XMLStreamWriter;
import lombok.extern.slf4j.Slf4j;
import net.sf.saxon.s9api.Processor;
import net.sf.saxon.s9api.Serializer;
import net.sf.saxon.s9api.Serializer.Property;
import org.fao.geonet.common.search.domain.UserInfo;
import org.fao.geonet.common.xml.XsltTransformerFactory;
import org.fao.geonet.common.xml.XsltUtil;
import org.fao.geonet.domain.Metadata;
import org.fao.geonet.index.model.gn.IndexRecordFieldNames;
import org.fao.geonet.repository.MetadataRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;


@Component("XmlResponseProcessorImpl")
@Slf4j(topic = "org.fao.geonet.common.search.processor")
public class XmlResponseProcessorImpl extends AbstractResponseProcessor {

  @Autowired
  MetadataRepository metadataRepository;

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

    generator.writeStartDocument("UTF-8", "1.0");
    {
      JsonParser parser = parserForStream(streamFromServer);

      List<Integer> ids = new ArrayList<>();
      ResponseParser responseParser = new ResponseParser();
      responseParser.matchHits(parser, generator, doc -> {
        ids.add(doc
            .get(IndexRecordFieldNames.source)
            .get(IndexRecordFieldNames.id).asInt());
      }, false);

      List<Metadata> records = metadataRepository.findAllById(ids);

      generator.writeStartElement("items");
      generator.writeAttribute("total", responseParser.total + "");
      generator.writeAttribute("relation", responseParser.totalRelation + "");
      generator.writeAttribute("took", responseParser.took + "");
      generator.writeAttribute("returned", records.size() + "");
      {
        records.forEach(r -> {
          String xsltFileName =
              "xslt/ogcapir/formats/xml/copy.xsl";
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
        });
      }
      generator.writeEndElement();
    }
    generator.writeEndDocument();
    generator.flush();
    generator.close();
  }
}
