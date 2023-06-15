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

  <xsl:variable name="resourcePrefix"
                select="normalize-space($env/metadata/resourceIdentifierPrefix)"/>
  
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
    <xsl:value-of select="concat($resourcePrefix,
                                  '{resourceType}/{resourceUuid}')"/>
  </xsl:function>
</xsl:stylesheet>
