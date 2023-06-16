<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dcat="http://www.w3.org/ns/dcat#"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:template match="rdf:RDF[dcat:Catalog]"
                mode="dcat"
                priority="2">
    <xsl:copy-of select="dcat:Catalog/*
                          /(dcat:CatalogRecord|dcat:Dataset|dcat:DatasetService)"/>
  </xsl:template>
</xsl:stylesheet>
