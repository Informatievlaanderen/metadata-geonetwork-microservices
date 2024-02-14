<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dcat="http://www.w3.org/ns/dcat#"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:template mode="dcat-record-reference" match="dcat:record|dcat:dataset|dcat:service">
    <xsl:copy copy-namespaces="no">
      <xsl:attribute name="rdf:about" select="string(*/@rdf:about)"/>
    </xsl:copy>
  </xsl:template>

  <xsl:template mode="dcat-record-reference" match="rdf:RDF[dcat:Catalog]|dcat:*">
    <xsl:apply-templates select="*" mode="dcat-record-reference"/>
  </xsl:template>

  <xsl:template mode="dcat" match="rdf:RDF[dcat:Catalog]" priority="2">
    <xsl:copy-of select="dcat:Catalog/*/(dcat:CatalogRecord|dcat:Dataset|dcat:DataService)"/>
  </xsl:template>
</xsl:stylesheet>
