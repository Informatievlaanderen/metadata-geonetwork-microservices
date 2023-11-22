<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:skos="http://www.w3.org/2004/02/skos/core#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:geonet="http://www.fao.org/geonetwork"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:function name="geonet:getRelatedServices" as="node()?">
    <xsl:param name="string" as="xs:string"/>

    <!-- TODO:
        https://github.com/GIM-be/core-geonetwork/blob/clients/aiv/main/core/src/main/java/org/fao/geonet/util/XslUtil.java#LL1051C24-L1051C42 -->
  </xsl:function>

</xsl:stylesheet>
