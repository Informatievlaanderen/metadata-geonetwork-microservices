<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:skos="http://www.w3.org/2004/02/skos/core#"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:geonet="http://www.fao.org/geonetwork"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  exclude-result-prefixes="#all"
  version="2.0">

  <!-- TODO: Comes from
  https://github.com/GIM-be/core-geonetwork/blob/clients/aiv/main/web/src/main/webapp/xslt/services/dcat/rdf.xsl#LL48C1-L49C1
  -->
  <xsl:variable name="env" as="node()">
    <env/>
  </xsl:variable>
  <xsl:variable name="resourcePrefix" select="$env/metadata/resourceIdentifierPrefix"/>


  <xsl:function name="geonet:getRelatedServices" as="node()?">
    <xsl:param name="string" as="xs:string"/>

    <!-- TODO:
        https://github.com/GIM-be/core-geonetwork/blob/clients/aiv/main/core/src/main/java/org/fao/geonet/util/XslUtil.java#LL1051C24-L1051C42 -->
  </xsl:function>

  <xsl:function name="geonet:getRelatedDatasets" as="node()?">
    <xsl:param name="string" as="xs:string"/>

    <!-- TODO:
        https://github.com/GIM-be/core-geonetwork/blob/clients/aiv/main/core/src/main/java/org/fao/geonet/util/XslUtil.java#L1089 -->
  </xsl:function>

  <xsl:function name="geonet:uuidFromString">
    <xsl:param name="string" as="xs:string"/>

    <!-- TODO:
        return UUID.nameUUIDFromBytes(str.getBytes()).toString(); -->
    <xsl:value-of select="$string"/>
  </xsl:function>

  <xsl:function name="geonet:getUriPattern">
    <xsl:param name="string" as="xs:string"/>

    <!-- TODO:
    if (metadata != null && metadata.getHarvestInfo().isHarvested()) {
            HarvesterSettingRepository harvesterSetting = context.getBean(HarvesterSettingRepository.class);
            HarvesterSetting uuidSetting = harvesterSetting.findOneByNameAndValueLike("uuid", metadata.getHarvestInfo().getUuid());
            if (uuidSetting != null && uuidSetting.getParent() != null) {
                List<HarvesterSetting> resourceUriPatternSetting = harvesterSetting.findChildrenByName(uuidSetting.getParent().getId(), "resourceUriPattern");
                if (resourceUriPatternSetting.size() > 0 && StringUtils.isNotEmpty(resourceUriPatternSetting.get(0).getValue())) {
                    return resourceUriPatternSetting.get(0).getValue();
                }
            }
        }
    return sm.getValue(Settings.SYSTEM_RESOURCE_PREFIX) + "/{resourceType}/{resourceUuid}";
     -->
    <xsl:value-of select="$string"/>
  </xsl:function>


  <xsl:variable name="thesaurusList" as="node()?">
    <!--<path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/featureconcept.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/GDI-Vlaanderen-service-types.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/GDI-Vlaanderen-trefwoorden.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/gemet.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/inspire-service-taxonomy.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/inspire-theme.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/PriorityDataset.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/theme/SpatialScope.rdf'"/></path>
    <path><xsl:value-of select="'classpath:xslt/ogcapir/formats/dcat/thesauri-AIV/place/GDI-Vlaanderenregios.rdf'"/></path>-->
  </xsl:variable>

  <xsl:variable name="thesauri">
    <xsl:for-each select="$thesaurusList/path">
      <xsl:variable name="currentDoc" select="document(.)"/>
      <thesausus>
        <xsl:attribute name="title"
                       select="string($currentDoc/rdf:RDF/skos:ConceptScheme/dc:title[1])"/>
        <xsl:attribute name="about"
                       select="string($currentDoc/rdf:RDF/skos:ConceptScheme/@rdf:about)"/>
        <xsl:for-each select="$currentDoc/rdf:RDF//skos:Concept">
          <xsl:copy copy-namespaces="no">
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="skos:prefLabel[@xml:lang = ('en','de','nl','fr')]"/>
          </xsl:copy>
        </xsl:for-each>
        <xsl:for-each select="$currentDoc/rdf:RDF//rdf:Description">
          <skos:Concept>
            <xsl:copy-of select="@*"/>
            <xsl:copy-of select="skos:prefLabel[@xml:lang = ('en','de','nl','fr')]"/>
          </skos:Concept>
        </xsl:for-each>
      </thesausus>
    </xsl:for-each>
  </xsl:variable>

  <xsl:template name="GetAboutFromCharacterString">
    <xsl:param name="keyword" as="xs:string"/>
    <xsl:param name="thesaurusIdentifier" as="xs:string"/>
    <xsl:param name="lang" as="xs:string"/>
    <xsl:variable name="thesaurus"
                  select="$thesauri/thesausus[@title = $thesaurusIdentifier or @about = $thesaurusIdentifier]"/>
    <xsl:value-of
      select="string($thesaurus/skos:Concept[skos:prefLabel[@xml:lang = $lang] = $keyword][1]/@rdf:about)"/>
  </xsl:template>

  <xsl:template name="GetSchemeFromThesaurusTitle">
    <xsl:param name="thesaurusTitle" as="xs:string"/>
    <xsl:value-of select="string($thesauri/thesausus[@title = $thesaurusTitle]/@about)"/>
  </xsl:template>
</xsl:stylesheet>
