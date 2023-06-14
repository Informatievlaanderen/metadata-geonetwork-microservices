<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:adms="http://www.w3.org/ns/adms#"
                xmlns:cnt="http://www.w3.org/2011/content#"
                xmlns:dcat="http://www.w3.org/ns/dcat#"
                xmlns:dct="http://purl.org/dc/terms/"
                xmlns:foaf="http://xmlns.com/foaf/0.1/"
                xmlns:gco="http://www.isotc211.org/2005/gco"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:gml="http://www.opengis.net/gml/3.2"
                xmlns:gml320="http://www.opengis.net/gml"
                xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:locn="http://www.w3.org/ns/locn#"
                xmlns:owl="http://www.w3.org/2002/07/owl#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:srv="http://www.isotc211.org/2005/srv"
                xmlns:vcard="http://www.w3.org/2006/vcard/ns#"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:geonet="http://www.fao.org/geonetwork"
                xmlns:geodcat="http://data.europa.eu/930/"
                xmlns:mdcat="https://data.vlaanderen.be/ns/metadata-dcat#"
                xmlns:adres="https://data.vlaanderen.be/ns/adres#"
                xmlns:vlgen="https://data.vlaanderen.be/ns/generiek"
                xmlns:dqv="http://www.w3.org/ns/dqv#"
                exclude-result-prefixes="#all"
                version="2.0">

  <xsl:output method="xml"
              omit-xml-declaration="yes"
              encoding="utf-8"/>


  <xsl:import href="classpath:xslt/ogcapir/formats/dcat/problems.xsl"/>
  <xsl:include href="classpath:xslt/ogcapir/formats/dcat/tpl-rdf-utils.xsl"/>
  <xsl:include href="classpath:xslt/ogcapir/formats/dcat/tpl-rdf-variables.xsl"/>



  <xsl:template match="gmd:MD_Metadata" mode="dcat">
    <xsl:variable name="MetadataViewUrl"
                  select="concat($catalogUrl, '/catalog.search#/metadata/', gmd:fileIdentifier/gco:CharacterString)"/>

    <xsl:variable name="MetadataXmlUrl"
                  select="concat(substring-before($resourcePrefix, '/resource'), '/api/records/', gmd:fileIdentifier/gco:CharacterString, '/formatters/xml')"/>

    <!-- Metadata language: corresponding Alpha-2 codes -->
    <xsl:variable name="RecordLang">
      <xsl:call-template name="ExtractLang">
        <xsl:with-param name="lang" select="gmd:language"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="MetadataLanguage">
      <xsl:call-template name="Alpha3-to-Alpha2">
        <xsl:with-param name="lang" select="$RecordLang"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:variable name="IsoScopeCode"
                  select="normalize-space(gmd:hierarchyLevel/gmd:MD_ScopeCode/@codeListValue)"/>

    <xsl:variable name="ResourceType"
                  select="if ($IsoScopeCode = 'dataset' or $IsoScopeCode = 'nonGeographicDataset')
                          then 'dataset'
                          else $IsoScopeCode"/>

    <xsl:variable name="MetadataDate"
                  select="geonet:formatRdfDate(gmd:dateStamp/*)"/>

    <xsl:variable name="RecordUUID"
                  select="string(gmd:fileIdentifier/gco:CharacterString)"/>

    <xsl:variable name="ResourceUUID"
                  select="geonet:getResourceUUID(.)"/>

    <xsl:variable name="uriPattern"
                  select="geonet:getUriPattern($RecordUUID)"/>

    <xsl:variable name="RecordURI">
      <xsl:variable name="mURI"
                    select="replace(replace($uriPattern, '\{resourceType\}', 'records'), '\{resourceUuid\}', $RecordUUID)"/>
      <xsl:if
        test="$mURI != '' and (starts-with($mURI, 'http://') or starts-with($mURI, 'https://'))">
        <xsl:value-of select="geonet:escapeURI($mURI)"/>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="ResourceUri"
                  select="geonet:getResourceURI(., $ResourceType, $uriPattern)"/>

    <xsl:variable name="ServiceType">
      <xsl:value-of select="gmd:identificationInfo/*/srv:serviceType/gco:LocalName"/>
    </xsl:variable>

    <xsl:variable name="ResourceTitle">
      <xsl:for-each select="gmd:identificationInfo[1]/*/gmd:citation/*/gmd:title">
        <dct:title xml:lang="{$MetadataLanguage}">
          <xsl:value-of select="normalize-space(gco:CharacterString)"/>
        </dct:title>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">dct:title</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="ResourceAbstract">
      <xsl:for-each select="gmd:identificationInfo[1]/*/gmd:abstract">
        <dct:description xml:lang="{$MetadataLanguage}">
          <xsl:value-of select="normalize-space(gco:CharacterString)"/>
        </dct:description>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">dct:description</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="LicenseConstraints">
      <xsl:variable name="constraints" select="gmd:identificationInfo[1]/*/gmd:resourceConstraints/*[name() = ('gmd:MD_LegalConstraints', 'gmd:MD_SecurityConstraints')]/gmd:otherConstraints[../gmd:useConstraints or ../gmd:accessConstraints]/*|
                                               gmd:identificationInfo[1]/*/gmd:resourceConstraints/*[name() = ('gmd:MD_LegalConstraints', 'gmd:MD_SecurityConstraints')]/gmd:useLimitation[not(../gmd:useConstraints or ../gmd:accessConstraints)]/*"/>

      <!-- Pick the first model license and map it to dct:license -->
      <xsl:variable name="modelLicences">
        <xsl:for-each select="$constraints[name() = 'gmx:Anchor']">
          <xsl:variable name="currentUrl" select="lower-case(@xlink:href)"/>
          <xsl:variable name="modelLicence"
                        select="$modelLicencieKeywords/license[count(urlKeyword[contains($currentUrl, .)]) > 0 and (not(scope) or count(scope[$ResourceType = .]) > 0)]/content/*"/>
          <xsl:if test="$modelLicence">
            <xsl:copy-of select="$modelLicence"/>
          </xsl:if>
        </xsl:for-each>
      </xsl:variable>
      <xsl:if test="normalize-space($modelLicences) != ''">
        <xsl:copy-of select="$modelLicences/*[1]"/>
      </xsl:if>
    </xsl:variable>

    <xsl:variable name="RightsConstraints">
      <xsl:variable name="constraints" select="gmd:identificationInfo[1]/*/gmd:resourceConstraints/*[name() = ('gmd:MD_LegalConstraints', 'gmd:MD_SecurityConstraints')]/gmd:otherConstraints[../gmd:useConstraints or ../gmd:accessConstraints]/*|
                                               gmd:identificationInfo[1]/*/gmd:resourceConstraints/*[name() = ('gmd:MD_LegalConstraints', 'gmd:MD_SecurityConstraints')]/gmd:useLimitation[not(../gmd:useConstraints or ../gmd:accessConstraints)]/*"/>
      <xsl:for-each select="$constraints">
        <xsl:variable name="currentUrl" select="lower-case(@xlink:href)"/>
        <xsl:variable name="modelLicence"
                      select="$modelLicencieKeywords/license[count(urlKeyword[contains($currentUrl, .)]) > 0 and (not(scope) or count(scope[$ResourceType = .]) > 0)]/content/*"/>
        <xsl:if test="not($modelLicence)">
          <dct:rights>
            <dct:RightsStatement>
              <xsl:if test="name() = 'gmx:Anchor'">
                <xsl:attribute name="rdf:about" select="@xlink:href"/>
              </xsl:if>
              <dct:title>
                <xsl:value-of select="string()"/>
              </dct:title>
            </dct:RightsStatement>
          </dct:rights>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="AccessRights">
      <!-- Mapping revised for compliance with the 2017 edition of the INSPIRE Metadata Technical Guidelines -->
      <xsl:variable name="noLimitationConstraint" select="gmd:identificationInfo/*/gmd:resourceConstraints/gmd:MD_LegalConstraints/gmd:otherConstraints/gmx:Anchor[
                                                            @xlink:href = ('http://inspire.ec.europa.eu/metadata-codelist/LimitationsOnPublicAccess/noLimitations','https://inspire.ec.europa.eu/metadata-codelist/LimitationsOnPublicAccess/noLimitations')
                                                          ]"/>
      <xsl:choose>
        <xsl:when test="count($noLimitationConstraint) > 0">
          <dct:accessRights>
            <skos:Concept
              rdf:about="http://publications.europa.eu/resource/authority/access-right/PUBLIC">
              <rdf:type rdf:resource="http://purl.org/dc/terms/RightsStatement"/>
              <xsl:choose>
                <xsl:when test="$ResourceType = 'service'">
                  <skos:prefLabel xml:lang="nl">Toegang zonder voorwaarden</skos:prefLabel>
                  <skos:prefLabel xml:lang="en">without conditions</skos:prefLabel>
                  <skos:prefLabel xml:lang="fr">without conditions</skos:prefLabel>
                  <skos:prefLabel xml:lang="de">without conditions</skos:prefLabel>
                </xsl:when>
                <xsl:otherwise>
                  <skos:prefLabel xml:lang="nl">publiek</skos:prefLabel>
                  <skos:prefLabel xml:lang="en">public</skos:prefLabel>
                  <skos:prefLabel xml:lang="fr">public</skos:prefLabel>
                  <skos:prefLabel xml:lang="de">public</skos:prefLabel>
                </xsl:otherwise>
              </xsl:choose>
              <skos:inScheme
                rdf:resource="http://publications.europa.eu/resource/authority/access-right"/>
            </skos:Concept>
          </dct:accessRights>
        </xsl:when>
        <xsl:otherwise>
          <dct:accessRights>
            <skos:Concept
              rdf:about="http://publications.europa.eu/resource/authority/access-right/NON_PUBLIC">
              <rdf:type rdf:resource="http://purl.org/dc/terms/RightsStatement"/>
              <xsl:choose>
                <xsl:when test="$ResourceType = 'service'">
                  <skos:prefLabel xml:lang="nl">Toegang met voorwaarden</skos:prefLabel>
                  <skos:prefLabel xml:lang="en">with conditions</skos:prefLabel>
                  <skos:prefLabel xml:lang="fr">with conditions</skos:prefLabel>
                  <skos:prefLabel xml:lang="de">with conditions</skos:prefLabel>
                </xsl:when>
                <xsl:otherwise>
                  <skos:prefLabel xml:lang="nl">niet publiek</skos:prefLabel>
                  <skos:prefLabel xml:lang="en">not public</skos:prefLabel>
                  <skos:prefLabel xml:lang="fr">not public</skos:prefLabel>
                  <skos:prefLabel xml:lang="de">not public</skos:prefLabel>
                </xsl:otherwise>
              </xsl:choose>
              <skos:inScheme
                rdf:resource="http://publications.europa.eu/resource/authority/access-right"/>
            </skos:Concept>
          </dct:accessRights>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <!-- Metadata character encoding -->
    <xsl:variable name="MetadataCharacterEncoding">
      <xsl:apply-templates select="gmd:characterSet/gmd:MD_CharacterSetCode"/>
    </xsl:variable>

    <xsl:variable name="ResourceCharacterEncoding">
      <xsl:for-each select="gmd:identificationInfo/gmd:MD_DataIdentification">
        <xsl:apply-templates select="gmd:characterSet/gmd:MD_CharacterSetCode"/>
      </xsl:for-each>
    </xsl:variable>

    <!-- Metadata description (metadata on metadata) -->
    <xsl:variable name="MetadataDescription">
      <dct:identifier>
        <xsl:value-of select="$RecordUUID"/>
      </dct:identifier>

      <xsl:if test="$RecordLang != ''">
        <xsl:variable name="languageConcept">
          <xsl:call-template name="Map-language">
            <xsl:with-param name="lang" select="lower-case($RecordLang)"/>
          </xsl:call-template>
        </xsl:variable>

        <xsl:choose>
          <xsl:when test="normalize-space($languageConcept) != ''">
            <dct:language>
              <xsl:copy-of select="$languageConcept"/>
            </dct:language>
          </xsl:when>
          <xsl:otherwise>
            <dct:language
              rdf:resource="{geonet:escapeURI(concat($oplang, lower-case($RecordLang)))}"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:if>

      <xsl:if test="$MetadataDate != ''">
        <dct:modified>
          <xsl:value-of select="$MetadataDate"/>
        </dct:modified>
      </xsl:if>

      <dct:conformsTo>
        <dct:Standard rdf:about="https://data.vlaanderen.be/doc/applicatieprofiel/GEODCAT-AP-VL/">
          <dct:title>Geodcat-ap-vl</dct:title>
          <owl:versionInfo>2.0</owl:versionInfo>
        </dct:Standard>
      </dct:conformsTo>

      <dct:source rdf:resource="{$MetadataXmlUrl}"/>
      <mdcat:landingpageVoorBronMetadata rdf:resource="{$MetadataViewUrl}"/>

      <xsl:if test="$MetadataCharacterEncoding != ''">
        <xsl:copy-of select="$MetadataCharacterEncoding"/>
      </xsl:if>
    </xsl:variable>

    <!-- Resource description (resource metadata) -->
    <xsl:variable name="ResourceDescription">
      <xsl:choose>
        <xsl:when test="$ResourceType = 'dataset'">
          <rdf:type rdf:resource="{$dcat}Dataset"/>
        </xsl:when>
        <xsl:when test="$ResourceType = 'series'">
          <rdf:type rdf:resource="{$dcat}Dataset"/>
        </xsl:when>
        <xsl:when test="$ResourceType = 'service'">
          <rdf:type rdf:resource="{$dcat}DataService"/>
        </xsl:when>
      </xsl:choose>

      <!-- Unique Resource identification info -->
      <dct:identifier>
        <xsl:value-of select="$ResourceUUID"/>
      </dct:identifier>
      <xsl:copy-of select="$ResourceTitle"/>
      <xsl:copy-of select="$ResourceAbstract"/>

      <!-- Keyword -->
      <xsl:variable name="keywordsRdfMapping">
        <xsl:apply-templates
          select="gmd:identificationInfo/*/gmd:descriptiveKeywords/gmd:MD_Keywords">
          <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
        </xsl:apply-templates>
        <xsl:apply-templates select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:alternateTitle|
            gmd:identificationInfo/*/gmd:aggregationInfo/gmd:MD_AggregateInformation/gmd:aggregateDataSetName/gmd:CI_Citation/gmd:alternateTitle">
          <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
        </xsl:apply-templates>
      </xsl:variable>

      <!-- mdcat:ISO-category -->
      <xsl:for-each select="gmd:identificationInfo/*/gmd:topicCategory/gmd:MD_TopicCategoryCode">
        <xsl:call-template name="Map-topicCategory">
          <xsl:with-param name="topicCategoryValue" select="normalize-space(.)"/>
        </xsl:call-template>
      </xsl:for-each>

      <xsl:if test="$ResourceType != 'service'">
        <xsl:if test="count($keywordsRdfMapping/dcat:theme) = 0">
          <xsl:variable name="dcatThemesByTopicCategory">
            <xsl:apply-templates select="gmd:identificationInfo/*/gmd:topicCategory"/>
          </xsl:variable>
          <xsl:for-each-group select="$dcatThemesByTopicCategory/dcat:theme"
                              group-by="skos:Concept/@rdf:about">
            <xsl:copy-of select="."/>
          </xsl:for-each-group>
          <xsl:if test="count($keywordsRdfMapping/dct:subject) = 0">
            <xsl:for-each-group select="$dcatThemesByTopicCategory/dct:subject"
                                group-by="@rdf:resource">
              <xsl:copy-of select="."/>
            </xsl:for-each-group>
          </xsl:if>
        </xsl:if>
      </xsl:if>
      <xsl:for-each-group select="$keywordsRdfMapping/dcat:theme"
                          group-by="skos:Concept/@rdf:about">
        <xsl:copy-of select="."/>
      </xsl:for-each-group>
      <xsl:for-each-group select="$keywordsRdfMapping/dcat:keyword"
                          group-by="concat('lang :', @xml:lang, ' val: ', string())">
        <xsl:copy-of select="."/>
      </xsl:for-each-group>
      <xsl:copy-of select="$keywordsRdfMapping/*[not(name()=('dcat:theme', 'dcat:keyword'))]"/>

      <!-- Content information -->
      <xsl:apply-templates select="gmd:contentInfo/*"/>

      <!-- Resource Language -->
      <xsl:for-each select="gmd:identificationInfo/*/gmd:language">
        <xsl:variable name="resLang">
          <xsl:call-template name="ExtractLang">
            <xsl:with-param name="lang" select="."/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:if test="normalize-space($resLang) != ''">
          <xsl:variable name="languageConcept">
            <xsl:call-template name="Map-language">
              <xsl:with-param name="lang" select="lower-case($resLang)"/>
            </xsl:call-template>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="normalize-space($languageConcept) != ''">
              <dct:language>
                <xsl:copy-of select="$languageConcept"/>
              </dct:language>
            </xsl:when>
            <xsl:otherwise>
              <dct:language
                rdf:resource="{geonet:escapeURI(concat($oplang, lower-case($RecordLang)))}"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
      </xsl:for-each>

      <!-- Temporal extent -->
      <xsl:apply-templates
        select="gmd:identificationInfo/*/gmd:extent/*/gmd:temporalElement/*"/>

      <!-- Creation date, publication date, date of last revision -->
      <xsl:apply-templates
        select="gmd:identificationInfo/*/gmd:citation/*/gmd:date/gmd:CI_Date"/>

      <!-- Conformity -->
      <xsl:apply-templates
        select="gmd:dataQualityInfo/*/gmd:report/*/gmd:result/*/gmd:specification/gmd:CI_Citation">
        <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
      </xsl:apply-templates>

      <!-- Responsible organisation -->
      <xsl:variable name="contacts">
        <xsl:for-each select="(.//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode/@codeListValue = 'publisher'])[1]|
                              (.//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode/@codeListValue = 'custodian'])[1]">
          <xsl:apply-templates select=".">
            <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
            <xsl:with-param name="ResourceType" select="$ResourceType"/>
          </xsl:apply-templates>
        </xsl:for-each>

        <xsl:for-each
          select=".//gmd:CI_ResponsibleParty[not(gmd:role/gmd:CI_RoleCode/@codeListValue = ('publisher', 'distributor', 'custodian'))]">
          <xsl:apply-templates select=".">
            <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
            <xsl:with-param name="ResourceType" select="$ResourceType"/>
          </xsl:apply-templates>
        </xsl:for-each>
      </xsl:variable>

      <xsl:for-each-group select="$contacts/*"
                          group-by="concat(name(), '|', string(vcard:Organization/vcard:organization-name[1]|foaf:Agent/foaf:name[1]))">
        <xsl:copy-of select="current-group()[1]"/>
      </xsl:for-each-group>

      <xsl:variable name="Distributors">
        <xsl:apply-templates
          select="(.//gmd:CI_ResponsibleParty[gmd:role/gmd:CI_RoleCode/@codeListValue = 'distributor' and name(..) != 'gmd:distributorContact'])[1]">
          <xsl:with-param name="MetadataLanguage" select="$MetadataLanguage"/>
          <xsl:with-param name="ResourceType" select="$ResourceType"/>
        </xsl:apply-templates>
      </xsl:variable>

      <!-- Spatial extend -->
      <xsl:apply-templates
        select="gmd:identificationInfo/*/*[self::gmd:extent|self::srv:extent]/*/gmd:geographicElement/gmd:EX_GeographicBoundingBox"/>

      <!-- spatial resolution -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:spatialResolution"/>

      <!-- Version information -->
      <xsl:apply-templates select="gmd:identificationInfo/*/gmd:citation/*/gmd:edition"/>

      <!-- Access Rights -->
      <xsl:copy-of select="$AccessRights"/>

      <!-- Metadata view page -->
      <mdcat:landingpageVoorBronMetadata rdf:resource="{$MetadataViewUrl}"/>

      <!-- Resource type specific -->
      <xsl:choose>
        <!-- Service specific -->
        <xsl:when test="$ResourceType = 'service'">
          <xsl:variable name="relatedDatasetByOperatesOn">
            <xsl:if test="$relationLookup">
              <xsl:copy-of select="geonet:getRelatedDatasets($RecordUUID)/datasets/*"/>
            </xsl:if>
          </xsl:variable>

          <!-- Transfer option -->
          <xsl:variable name="distribution" select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine[
                                                      gmd:CI_OnlineResource/gmd:protocol/gco:CharacterString = ('OGC:WMS', 'OGC:WFS', 'OGC:WCS', 'OGC:WMTS') and
                                                      gmd:CI_OnlineResource/gmd:linkage/gmd:URL
                                                    ][1]/gmd:CI_OnlineResource/gmd:linkage[1]/gmd:URL[1]"/>
          <xsl:if test="$distribution">
            <dcat:endpointDescription rdf:resource="{normalize-space($distribution)}"/>
            <dcat:endpointURL rdf:resource="{normalize-space(tokenize($distribution, '\?')[1])}"/>
          </xsl:if>

          <!-- Online resources -->
          <xsl:for-each-group
            select="gmd:distributionInfo/gmd:MD_Distribution/gmd:transferOptions/gmd:MD_DigitalTransferOptions/gmd:onLine/gmd:CI_OnlineResource/gmd:protocol/*"
            group-by=".">
            <!-- Conform to standard -->
            <xsl:if test="normalize-space(current-grouping-key()) != ''">
              <xsl:call-template name="Map-protocol">
                <xsl:with-param name="protocol" select="current-grouping-key()"/>
              </xsl:call-template>
            </xsl:if>
          </xsl:for-each-group>
          <xsl:copy-of select="$LicenseConstraints"/>
          <xsl:copy-of select="$RightsConstraints"/>

          <xsl:variable name="datasetUriPattern"
                        select="geonet:getUriPattern($RecordUUID)"/>
          <!-- Coupled resources -->
          <xsl:if test="$relationLookup and count(gmd:identificationInfo/*/srv:operatesOn) > 0">
            <xsl:variable name="operatesOn" select="gmd:identificationInfo/*/srv:operatesOn"/>
            <xsl:for-each select="$relatedDatasetByOperatesOn/*">
              <xsl:choose>
                <xsl:when test="name() = 'gmd:MD_Metadata'">
                  <dcat:servesDataset>
                    <dcat:Dataset
                      rdf:about="{geonet:getResourceURI(., 'dataset', $datasetUriPattern)}">
                      <xsl:variable name="dsIdentifiers">
                        <xsl:for-each
                          select="gmd:identificationInfo[1]/*/gmd:citation/*/gmd:identifier/*">
                          <xsl:choose>
                            <xsl:when test="gmd:codeSpace/gco:CharacterString/text() != ''">
                              <xsl:value-of
                                select="concat(gmd:codeSpace/gco:CharacterString/text(), gmd:code/gco:CharacterString/text())"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <xsl:value-of select="gmd:code/gco:CharacterString/text()"/>
                            </xsl:otherwise>
                          </xsl:choose>
                        </xsl:for-each>
                      </xsl:variable>
                      <xsl:variable name="link"
                                    select="normalize-space($operatesOn[@uuidref = $dsIdentifiers][1]/@xlink:href)"/>
                      <dct:identifier>
                        <xsl:value-of select="gmd:fileIdentifier/gco:CharacterString"/>
                      </dct:identifier>
                      <dct:title>
                        <xsl:value-of
                          select="gmd:identificationInfo/*/gmd:citation/gmd:CI_Citation/gmd:title/gco:CharacterString"/>
                      </dct:title>
                      <xsl:if test="$link != ''">
                        <dct:conformsTo rdf:resource="{$link}"/>
                      </xsl:if>
                    </dcat:Dataset>
                  </dcat:servesDataset>
                </xsl:when>
                <xsl:when test="name() = 'rdf:RDF'">
                  <dct:relation rdf:resource="{geonet:escapeURI(.//dcat:Dataset[1]/@rdf:about)}"/>
                </xsl:when>
              </xsl:choose>
            </xsl:for-each>
          </xsl:if>

          <!-- Service type and category -->

          <xsl:call-template name="Map-serviceType">
            <xsl:with-param name="codeSpace"
                            select="string(gmd:identificationInfo/*/srv:serviceType/gco:LocalName/@codeSpace)"/>
            <xsl:with-param name="localName"
                            select="string(gmd:identificationInfo/*/srv:serviceType/gco:LocalName)"/>
          </xsl:call-template>
          <xsl:for-each select="gmd:identificationInfo/*/gmd:descriptiveKeywords/gmd:MD_Keywords/gmd:keyword/gmx:Anchor[
                                  starts-with(@xlink:href, 'http://inspire.ec.europa.eu/metadata-codelist/SpatialDataServiceCategory/') or
                                  starts-with(@xlink:href, 'https://inspire.ec.europa.eu/metadata-codelist/SpatialDataServiceCategory/')]">
            <xsl:call-template name="Map-serviceCategory">
              <xsl:with-param name="serviceCategoryUri" select="@xlink:href"/>
            </xsl:call-template>
          </xsl:for-each>

          <!-- Always set development status to "production" and life phase to "live" -->
          <mdcat:levensfase>
            <skos:Concept rdf:about="https://data.vlaanderen.be/id/concept/levensfase/live">
              <skos:prefLabel xml:lang="nl">live</skos:prefLabel>
              <skos:prefLabel xml:lang="en">live</skos:prefLabel>
              <skos:prefLabel xml:lang="fr">live</skos:prefLabel>
              <skos:prefLabel xml:lang="de">live</skos:prefLabel>
              <skos:inScheme rdf:resource="https://data.vlaanderen.be/id/conceptscheme/levensfase"/>
            </skos:Concept>
          </mdcat:levensfase>
          <mdcat:ontwikkelingstoestand>
            <skos:Concept
              rdf:about="https://data.vlaanderen.be/id/concept/ontwikkelingstoestand/PROD">
              <skos:prefLabel xml:lang="nl">productie</skos:prefLabel>
              <skos:prefLabel xml:lang="en">production</skos:prefLabel>
              <skos:prefLabel xml:lang="de">production</skos:prefLabel>
              <skos:prefLabel xml:lang="fr">production</skos:prefLabel>
              <skos:inScheme
                rdf:resource="https://data.vlaanderen.be/id/conceptscheme/ontwikkelingstoestand"/>
            </skos:Concept>
          </mdcat:ontwikkelingstoestand>
        </xsl:when>

        <!-- Dataset specific -->
        <xsl:when test="$ResourceType = 'dataset' or $ResourceType = 'series'">
          <!-- Bbox -->
          <xsl:apply-templates mode="bbox"
                               select="gmd:identificationInfo/*/*[self::gmd:extent|self::srv:extent]/*/gmd:geographicElement/gmd:EX_GeographicBoundingBox"/>

          <!-- Reference system information -->
          <xsl:apply-templates select="gmd:referenceSystemInfo"/>

          <!-- Lineage -->
          <xsl:for-each select="gmd:dataQualityInfo/*/gmd:lineage/*/gmd:statement">
            <dct:provenance>
              <dct:ProvenanceStatement>
                <xsl:attribute name="rdf:about"
                               select="concat($MetadataViewUrl, '/formatters/lineage')"/>
                <dct:title xml:lang="{$MetadataLanguage}">
                  <xsl:value-of select="normalize-space(gco:CharacterString)"/>
                </dct:title>
                <xsl:call-template name="LocalisedString">
                  <xsl:with-param name="term">dct:title</xsl:with-param>
                </xsl:call-template>
              </dct:ProvenanceStatement>
            </dct:provenance>
          </xsl:for-each>

          <!-- Maintenance information (tentative) -->
          <xsl:apply-templates
            select="gmd:identificationInfo/*/gmd:resourceMaintenance/gmd:MD_MaintenanceInformation/gmd:maintenanceAndUpdateFrequency/gmd:MD_MaintenanceFrequencyCode"/>

          <!-- Related services -->
          <xsl:variable name="relatedServices">
            <xsl:if test="$relationLookup">
              <xsl:copy-of select="geonet:getRelatedServices($RecordUUID)/services/*"/>
            </xsl:if>
          </xsl:variable>
          <xsl:for-each select="$relatedServices/*">
            <xsl:choose>
              <xsl:when test="name() = 'gmd:MD_Metadata'">
                <xsl:variable name="serviceUriPattern"
                              select="geonet:getUriPattern(gmd:fileIdentifier/gco:CharacterString)"/>
                <dct:relation
                  rdf:resource="{geonet:getResourceURI(., 'service', $serviceUriPattern)}"/>
              </xsl:when>
              <xsl:when test="name() = 'rdf:RDF'">
                <dct:relation rdf:resource="{geonet:escapeURI(.//dcat:DataService[1]/@rdf:about)}"/>
              </xsl:when>
            </xsl:choose>
          </xsl:for-each>

          <!-- Spatial representation type -->
          <xsl:apply-templates
            select="gmd:identificationInfo/*/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode"/>

          <!-- Progress code -->
          <xsl:apply-templates
            select="gmd:identificationInfo/*/gmd:status/gmd:MD_ProgressCode[ends-with(@codeList,'#MD_ProgressCode')]"/>

          <!-- Distributions -->
          <xsl:for-each select="gmd:distributionInfo/gmd:MD_Distribution">
            <!-- Encoding -->
            <xsl:variable name="BaseEncoding">
              <xsl:apply-templates select="gmd:distributionFormat/gmd:MD_Format/gmd:name/*"/>
            </xsl:variable>

            <!-- Resource locators (access / download URLs) -->
            <xsl:for-each select="gmd:transferOptions/*/gmd:onLine/*">
              <xsl:variable name="Title">
                <xsl:for-each select="gmd:name">
                  <dct:title xml:lang="{$MetadataLanguage}">
                    <xsl:value-of select="normalize-space(gco:CharacterString)"/>
                  </dct:title>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">dct:title</xsl:with-param>
                  </xsl:call-template>
                </xsl:for-each>
                <xsl:for-each select="gmd:protocol[not(../gmd:name)]">
                  <dct:title xml:lang="{$MetadataLanguage}">
                    <xsl:value-of select="normalize-space(gco:CharacterString)"/>
                  </dct:title>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">dct:title</xsl:with-param>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:variable>

              <xsl:variable name="LayerName"
                            select="normalize-space(gmd:name[1]/gco:CharacterString)"/>

              <xsl:variable name="Protocol" select="gmd:protocol/*/text()"/>

              <xsl:variable name="isDownload"
                            select="starts-with($Protocol, 'WWW:DOWNLOAD-1.0') or $Protocol = 'LINK download-store'"/>

              <xsl:variable name="Description">
                <xsl:for-each select="gmd:description">
                  <dct:description xml:lang="{$MetadataLanguage}">
                    <xsl:choose>
                      <xsl:when test="$isDownload">
                        <xsl:value-of select="normalize-space(gco:CharacterString)"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:value-of
                          select="concat(normalize-space(gco:CharacterString), ' (De accessURL verwijst naar een gelimiteerde set van data, volgens de INSPIRE afspraken)')"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </dct:description>
                  <xsl:call-template name="LocalisedString">
                    <xsl:with-param name="term">dct:description</xsl:with-param>
                  </xsl:call-template>
                </xsl:for-each>
              </xsl:variable>


              <xsl:variable name="linkage" select="geonet:escapeURI(gmd:linkage[1]/gmd:URL[1])"/>

              <xsl:variable name="Function"
                            select="gmd:function/gmd:CI_OnLineFunctionCode/@codeListValue"/>

              <xsl:choose>
                <xsl:when
                  test="normalize-space($Function) = ('download', 'offlineAccess', 'order', '')">
                  <xsl:if test="starts-with($Protocol, 'WWW:DOWNLOAD-1.0') or
                                $Protocol = 'LINK download-store' or
                                ends-with($Protocol, 'get-map') or
                                ends-with($Protocol, 'get-tile') or
                                ends-with($Protocol, 'get-feature') or
                                ends-with($Protocol, 'get-coverage') or
                                (starts-with($Protocol, 'OGC:OGC-API-Features') and not(ends-with($Protocol, '-landingpage')))">

                    <xsl:variable name="encoding">
                      <xsl:choose>
                        <xsl:when test="$isDownload">
                          <xsl:copy-of select="$BaseEncoding"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <dct:format/>
                        </xsl:otherwise>
                      </xsl:choose>
                    </xsl:variable>

                    <xsl:for-each select="$encoding/dct:format">
                      <dcat:distribution>
                        <dcat:Distribution>
                          <xsl:variable name="distroUUID" select="geonet:uuidFromString(normalize-space(concat(
                            $Title,
                            $Description,
                            string($linkage),
                            string($LicenseConstraints),
                            string($RightsConstraints),
                            string(.),
                            string($Protocol),
                            string($Distributors)
                          )))"/>
                          <xsl:variable name="dURI"
                                        select="replace(replace($uriPattern, '\{resourceType\}', 'distributions'), '\{resourceUuid\}', $distroUUID)"/>
                          <xsl:if
                            test="$dURI != '' and (starts-with($dURI, 'http://') or starts-with($dURI, 'https://'))">
                            <xsl:attribute name="rdf:about" select="geonet:escapeURI($dURI)"/>
                          </xsl:if>
                          <dct:identifier>
                            <xsl:value-of select="$distroUUID"/>
                          </dct:identifier>
                          <xsl:copy-of select="$Title"/>
                          <xsl:copy-of select="$Description"/>
                          <dcat:accessURL rdf:resource="{geonet:escapeURI($linkage)}"/>

                          <xsl:call-template name="Map-protocol">
                            <xsl:with-param name="protocol" select="$Protocol"/>
                          </xsl:call-template>
                          <xsl:if test="not($isDownload) and $LayerName != ''">
                            <adms:identifier>
                              <adms:Identifier>
                                <skos:notation>
                                  <xsl:choose>
                                    <xsl:when test="contains($Protocol, 'WMS')">
                                      <xsl:attribute name="rdf:datatype"
                                                     select="'http://www.opengis.net/wms#Layer'"/>
                                    </xsl:when>
                                    <xsl:when test="contains($Protocol, 'WMTS')">
                                      <xsl:attribute name="rdf:datatype"
                                                     select="'http://schemas.opengis.net/wmts#Layer'"/>
                                    </xsl:when>
                                    <xsl:when test="contains($Protocol, 'WFS')">
                                      <xsl:attribute name="rdf:datatype"
                                                     select="'http://www.opengis.net/wfs#FeatureType'"/>
                                    </xsl:when>
                                    <xsl:when test="contains($Protocol, 'WCS')">
                                      <xsl:attribute name="rdf:datatype"
                                                     select="'http://www.opengis.net/wcs#CoverageDescription'"/>
                                    </xsl:when>
                                    <xsl:when test="starts-with($Protocol, 'OGC:OGC-API-Features')">
                                      <xsl:attribute name="rdf:datatype"
                                                     select="'http://www.opengis.net/ogcapi-features-1/1.0#Collection'"/>
                                    </xsl:when>
                                  </xsl:choose>
                                  <xsl:value-of select="$LayerName"/>
                                </skos:notation>
                              </adms:Identifier>
                            </adms:identifier>
                          </xsl:if>

                          <xsl:variable name="servedService">
                            <xsl:for-each select="$relatedServices/*">
                              <xsl:if
                                test=".//gmd:onLine//gmd:linkage/gmd:URL[starts-with($linkage, tokenize(., '\?')[1])]">
                                <resourceURI>
                                  <xsl:variable name="serviceUriPattern"
                                                select="geonet:getUriPattern(gmd:fileIdentifier/gco:CharacterString)"/>
                                  <xsl:value-of
                                    select="geonet:getResourceURI(., 'service', $serviceUriPattern)"/>
                                </resourceURI>
                                <uuid>
                                  <xsl:value-of select="gmd:fileIdentifier/gco:CharacterString"/>
                                </uuid>
                              </xsl:if>
                            </xsl:for-each>
                          </xsl:variable>

                          <xsl:copy-of select="$LicenseConstraints"/>

                          <xsl:choose>
                            <xsl:when test="$isDownload">
                              <xsl:copy-of select="$RightsConstraints"/>
                              <xsl:copy-of select="."/>
                            </xsl:when>
                            <xsl:when test="$servedService/resourceURI">
                              <dcat:accessService rdf:resource="{$servedService/resourceURI[1]}"/>
                              <dct:rights
                                rdf:resource="{concat($catalogUrl, '/catalog.search#/metadata/', $servedService/uuid[1], '/formatters/legalconstraints')}"/>
                            </xsl:when>
                            <xsl:otherwise>
                              <dct:rights>
                                <dct:RightsStatement>
                                  <dct:title>Hoewel deze hier niet zijn opgegeven, kunnen er
                                    voorwaarden verbonden zijn aan de toegang tot en het gebruik van
                                    deze webservice/API waarmee u toegang kunt krijgen tot de
                                    gegevens van deze dataset.
                                    Gelieve de metadata van de betreffende service/API te
                                    raadplegen, of contact op te nemen met de aanbieder van de de
                                    gegevensbron of de service/API.
                                  </dct:title>
                                </dct:RightsStatement>
                              </dct:rights>
                              <xsl:copy-of select="$RightsConstraints"/>
                            </xsl:otherwise>
                          </xsl:choose>

                          <xsl:copy-of select="$Distributors"/>

                          <xsl:if test="$ResourceCharacterEncoding != ''">
                            <xsl:copy-of select="$ResourceCharacterEncoding"/>
                          </xsl:if>
                        </dcat:Distribution>
                      </dcat:distribution>
                    </xsl:for-each>
                  </xsl:if>
                </xsl:when>

                <xsl:when test="$Function = ('information', 'search')">
                  <foaf:page rdf:resource="{geonet:escapeURI(.)}"/>
                </xsl:when>

                <xsl:otherwise>
                  <dcat:landingPage rdf:resource="{$linkage}"/>
                </xsl:otherwise>
              </xsl:choose>

            </xsl:for-each>
          </xsl:for-each>

          <!-- gmd:graphical-->
          <xsl:for-each
            select="gmd:identificationInfo/gmd:MD_DataIdentification/gmd:graphicOverview/gmd:MD_BrowseGraphic">
            <xsl:variable name="fileName"
                          select="geonet:escapeURI(normalize-space(gmd:fileName/*/text()))"/>
            <xsl:variable name="fileType" select="normalize-space(gmd:fileType/*/text())"/>
            <xsl:variable name="fileDescription"
                          select="normalize-space(gmd:fileDescription/*/text())"/>
            <xsl:if test="$fileName">
              <adms:sample>
                <dcat:Distribution>
                  <dcat:downloadURL rdf:resource="{$fileName}"/>
                  <xsl:if test="$fileType">
                    <xsl:call-template name="Map-media-type">
                      <xsl:with-param name="mediaType" select="$fileType"/>
                    </xsl:call-template>
                  </xsl:if>
                  <xsl:if test="$fileDescription">
                    <dct:title xml:lang="{$MetadataLanguage}">
                      <xsl:value-of select="$fileDescription"/>
                    </dct:title>
                  </xsl:if>
                </dcat:Distribution>
              </adms:sample>
            </xsl:if>
          </xsl:for-each>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <!-- Output Catalog record and resource description -->
    <xsl:choose>
      <xsl:when test="$ResourceUri != ''">
        <xsl:choose>
          <xsl:when test="$RecordURI != ''">
            <dcat:CatalogRecord>
              <xsl:if test="normalize-space($RecordURI) != ''">
                <xsl:attribute name="rdf:about" select="$RecordURI"/>
              </xsl:if>
              <foaf:primaryTopic rdf:resource="{$ResourceUri}"/>
              <adms:identifier>
                <adms:Identifier>
                  <skos:notation>
                    <xsl:value-of select="$RecordURI"/>
                  </skos:notation>
                  <vlgen:lokaleIdentificator>
                    <xsl:value-of select="$RecordUUID"/>
                  </vlgen:lokaleIdentificator>
                  <vlgen:naamruimte>
                    <xsl:value-of select="replace($RecordURI, concat('/', $RecordUUID), '')"/>
                  </vlgen:naamruimte>
                  <dct:creator>
                    <xsl:variable name="creatorUri">
                      <xsl:if test="contains($env/metadata/resourceIdentifierPrefix, '/srv/')">
                        <xsl:value-of
                          select="normalize-space(substring-before($env/metadata/resourceIdentifierPrefix, '/srv/'))"/>
                      </xsl:if>
                    </xsl:variable>
                    <xsl:choose>
                      <xsl:when test="$creatorUri != ''">
                        <xsl:attribute name="rdf:resource" select="$creatorUri"/>
                      </xsl:when>
                      <xsl:otherwise>
                        <xsl:attribute name="rdf:resource"
                                       select="'https://metadata.vlaanderen.be'"/>
                      </xsl:otherwise>
                    </xsl:choose>
                  </dct:creator>
                </adms:Identifier>
              </adms:identifier>
              <xsl:copy-of select="$MetadataDescription"/>
            </dcat:CatalogRecord>
          </xsl:when>

          <xsl:otherwise>
            <xsl:if test="normalize-space($MetadataDescription)">
              <dcat:CatalogRecord>
                <foaf:primaryTopic rdf:resource="{$ResourceUri}"/>
                <xsl:copy-of select="$MetadataDescription"/>
              </dcat:CatalogRecord>
            </xsl:if>
          </xsl:otherwise>
        </xsl:choose>

        <xsl:element name="{geonet:getElementName($ResourceDescription)}">
          <xsl:if test="normalize-space($ResourceUri) != ''">
            <xsl:attribute name="rdf:about" select="$ResourceUri"/>
          </xsl:if>
          <xsl:if test="geonet:isResourceUUIDGenerated(., $ResourceUri) = 'true'">
            <adms:identifier>
              <adms:Identifier>
                <skos:notation>
                  <xsl:value-of select="$ResourceUri"/>
                </skos:notation>
                <dct:creator rdf:resource="https://metadata.vlaanderen.be"/>
              </adms:Identifier>
            </adms:identifier>
          </xsl:if>
          <xsl:for-each select="$ResourceDescription/*[name() != 'rdf:type']">
            <xsl:copy-of select="."/>
          </xsl:for-each>
        </xsl:element>
      </xsl:when>

      <xsl:otherwise>
        <xsl:element name="{geonet:getElementName($ResourceDescription)}">
          <xsl:if test="normalize-space($MetadataDescription)">
            <foaf:isPrimaryTopicOf>
              <dcat:CatalogRecord>
                <xsl:copy-of select="$MetadataDescription"/>
              </dcat:CatalogRecord>
            </foaf:isPrimaryTopicOf>
          </xsl:if>
          <xsl:for-each select="$ResourceDescription/*[name() != 'rdf:type']">
            <xsl:copy-of select="."/>
          </xsl:for-each>
        </xsl:element>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!--
    Templates for specific metadata elements
    ========================================
  -->
  <!-- Responsible Organisation -->
  <xsl:template name="ResponsibleOrganisation"
                match="gmd:pointOfContact/gmd:CI_ResponsibleParty|gmd:contact/gmd:CI_ResponsibleParty">
    <xsl:param name="MetadataLanguage"/>
    <xsl:param name="ResourceType"/>

    <xsl:variable name="role" select="gmd:role/gmd:CI_RoleCode/@codeListValue"/>

    <xsl:variable name="IndividualURI" select="geonet:escapeURI(gmd:individualName/*/@xlink:href)"/>

    <xsl:variable name="IndividualName" select="normalize-space(gmd:individualName/*)"/>

    <xsl:variable name="IndividualName-vCard">
      <xsl:for-each select="gmd:individualName">
        <vcard:fn xml:lang="{$MetadataLanguage}">
          <xsl:value-of
            select="normalize-space(*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        </vcard:fn>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">vcard:fn</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="OrganisationURI"
                  select="geonet:escapeURI(gmd:organisationName/*/@xlink:href)"/>

    <xsl:variable name="URI">
      <xsl:choose>
        <xsl:when test="$IndividualURI != ''">
          <xsl:value-of select="$IndividualURI"/>
        </xsl:when>
        <xsl:when test="$OrganisationURI != ''">
          <xsl:value-of select="$OrganisationURI"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="OrganisationName"
                  select="normalize-space(gmd:organisationName/*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>

    <xsl:variable name="OrganisationName-FOAF">
      <xsl:for-each select="gmd:organisationName">
        <foaf:name xml:lang="{$MetadataLanguage}">
          <xsl:value-of
            select="normalize-space(*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        </foaf:name>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">foaf:name</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="OrganisationName-vCard">
      <xsl:for-each select="gmd:organisationName">
        <vcard:organization-name xml:lang="{$MetadataLanguage}">
          <xsl:value-of
            select="normalize-space(*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        </vcard:organization-name>
        <xsl:call-template name="LocalisedString">
          <xsl:with-param name="term">vcard:organization-name</xsl:with-param>
        </xsl:call-template>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="OrganisationNameAsIndividualName-vCard">
      <xsl:for-each select="gmd:organisationName">
        <xsl:variable name="orgName"
                      select="normalize-space(*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        <xsl:if test="$orgName != ''">
          <vcard:fn xml:lang="{$MetadataLanguage}">
            <xsl:value-of select="$orgName"/>
          </vcard:fn>
          <xsl:call-template name="LocalisedString">
            <xsl:with-param name="term">vcard:fn</xsl:with-param>
          </xsl:call-template>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="Email">
      <xsl:for-each
        select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/*">
        <xsl:variable name="address" select="geonet:escapeURI(.)"/>
        <xsl:if test="$address != ''">
          <foaf:mbox rdf:resource="mailto:{$address}"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="Email-vCard">
      <xsl:for-each
        select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address/gmd:electronicMailAddress/*">
        <xsl:variable name="address" select="geonet:escapeURI(.)"/>
        <xsl:if test="$address != ''">
          <vcard:hasEmail rdf:resource="mailto:{$address}"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="URL">
      <xsl:for-each
        select="gmd:contactInfo/gmd:CI_Contact/gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL">
        <xsl:variable name="homepage" select="geonet:escapeURI(.)"/>
        <xsl:if test="$homepage != ''">
          <foaf:workplaceHomepage rdf:resource="{$homepage}"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="URL-vCard">
      <xsl:for-each
        select="gmd:contactInfo/gmd:CI_Contact/gmd:onlineResource/gmd:CI_OnlineResource/gmd:linkage/gmd:URL">
        <xsl:variable name="url" select="geonet:escapeURI(.)"/>
        <xsl:if test="$url != ''">
          <vcard:hasURL rdf:resource="{$url}"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="Telephone">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:voice/*">
        <xsl:variable name="tel"
                      select="translate(translate(translate(translate(translate(normalize-space(.),' ',''),'(',''),')',''),'+',''),'.','')"/>
        <xsl:if test="$tel != ''">
          <foaf:phone rdf:resource="tel:+{$tel}"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="Telephone-vCard">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:phone/gmd:CI_Telephone/gmd:voice/*">
        <xsl:variable name="tel"
                      select="translate(translate(translate(translate(translate(normalize-space(.),' ',''),'(',''),')',''),'+',''),'.','')"/>
        <xsl:if test="$tel != ''">
          <vcard:hasTelephone rdf:resource="tel:+{$tel}"/>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="Address-vCard">
      <xsl:for-each select="gmd:contactInfo/gmd:CI_Contact/gmd:address/gmd:CI_Address">
        <xsl:variable name="deliveryPoint"
                      select="normalize-space(gmd:deliveryPoint/*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        <xsl:variable name="city"
                      select="normalize-space(gmd:city/*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        <xsl:variable name="administrativeArea"
                      select="normalize-space(gmd:administrativeArea/*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        <xsl:variable name="postalCode" select="normalize-space(gmd:postalCode/*)"/>
        <xsl:variable name="country"
                      select="normalize-space(gmd:country/*[name() = ('gco:CharacterString', 'gmx:Anchor')])"/>
        <xsl:if
          test="$deliveryPoint != '' or $city != '' or $administrativeArea != '' or $postalCode != '' or $country != ''">
          <locn:address>
            <locn:Address>
              <!--
              <locn:thoroughfare><xsl:value-of select="$deliveryPoint"/></locn:thoroughfare>
              <locn:postName><xsl:value-of select="$city"/></locn:postName>
              <locn:adminUnitL1><xsl:value-of select="$country"/></locn:adminUnitL1>
              -->
              <xsl:if test="$city != ''">
                <adres:gemeentenaam>
                  <xsl:value-of select="$city"/>
                </adres:gemeentenaam>
              </xsl:if>
              <xsl:if test="$administrativeArea != ''">
                <locn:adminUnitL2>
                  <xsl:value-of select="$administrativeArea"/>
                </locn:adminUnitL2>
              </xsl:if>
              <xsl:if test="$country != ''">
                <adres:land>
                  <xsl:value-of select="$country"/>
                </adres:land>
              </xsl:if>
              <xsl:if test="$postalCode != ''">
                <locn:postCode>
                  <xsl:value-of select="$postalCode"/>
                </locn:postCode>
              </xsl:if>
              <locn:fullAddress>
                <xsl:value-of
                  select="concat($deliveryPoint, ' ', $postalCode, ' ', $city, ' ', $country)"/>
              </locn:fullAddress>
            </locn:Address>
          </locn:address>
          <!-- update by GIM: use vcard:Address in addition to locn:Address -->
          <vcard:hasAddress>
            <vcard:Address>
              <xsl:if test="$deliveryPoint != ''">
                <vcard:street-address>
                  <xsl:value-of select="$deliveryPoint"/>
                </vcard:street-address>
              </xsl:if>
              <xsl:if test="$city != ''">
                <vcard:locality>
                  <xsl:value-of select="$city"/>
                </vcard:locality>
              </xsl:if>
              <xsl:if test="$administrativeArea != ''">
                <vcard:region>
                  <xsl:value-of select="$administrativeArea"/>
                </vcard:region>
              </xsl:if>
              <xsl:if test="$postalCode != ''">
                <vcard:postal-code>
                  <xsl:value-of select="$postalCode"/>
                </vcard:postal-code>
              </xsl:if>
              <xsl:if test="$country != ''">
                <vcard:country-name>
                  <xsl:value-of select="$country"/>
                </vcard:country-name>
              </xsl:if>
            </vcard:Address>
          </vcard:hasAddress>
        </xsl:if>
      </xsl:for-each>
    </xsl:variable>

    <xsl:variable name="ROInfo">
      <xsl:variable name="info">
        <xsl:if test="$OrganisationName != ''">
          <xsl:copy-of select="$OrganisationName-FOAF"/>
        </xsl:if>
        <xsl:copy-of select="$Telephone"/>
        <xsl:copy-of select="$Email"/>
        <xsl:copy-of select="$URL"/>
        <xsl:copy-of select="$Address-vCard"/>
      </xsl:variable>

      <foaf:Agent>
        <xsl:choose>
          <xsl:when test="$IndividualURI != ''">
            <xsl:attribute name="rdf:about" select="$IndividualURI"/>
          </xsl:when>
          <xsl:when test="$OrganisationURI != ''">
            <xsl:attribute name="rdf:about" select="$OrganisationURI"/>
          </xsl:when>
        </xsl:choose>
        <xsl:copy-of select="$info"/>
      </foaf:Agent>
    </xsl:variable>

    <xsl:variable name="ResponsibleParty">
      <xsl:variable name="info">
        <xsl:if test="$IndividualName != ''">
          <xsl:copy-of select="$IndividualName-vCard"/>
        </xsl:if>
        <xsl:if test="$OrganisationName != ''">
          <xsl:copy-of select="$OrganisationName-vCard"/>
        </xsl:if>
        <xsl:if test="$IndividualName = ''">
          <xsl:copy-of select="$OrganisationNameAsIndividualName-vCard"/>
        </xsl:if>
        <xsl:copy-of select="$Address-vCard"/>
        <xsl:copy-of select="$Email-vCard"/>
        <xsl:copy-of select="$URL-vCard"/>
        <xsl:copy-of select="$Telephone-vCard"/>
      </xsl:variable>

      <vcard:Organization>
        <xsl:choose>
          <xsl:when test="$IndividualURI != ''">
            <xsl:attribute name="rdf:about" select="$IndividualURI"/>
          </xsl:when>
          <xsl:when test="$OrganisationURI != ''">
            <xsl:attribute name="rdf:about" select="$OrganisationURI"/>
          </xsl:when>
        </xsl:choose>
        <xsl:copy-of select="$info"/>
      </vcard:Organization>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$ResourceType = 'service'">
        <xsl:choose>
          <xsl:when test="$role = 'pointOfContact'">
            <dcat:contactPoint>
              <xsl:copy-of select="$ResponsibleParty"/>
            </dcat:contactPoint>
          </xsl:when>
          <xsl:when test="$role = 'custodian'">
            <dct:publisher>
              <xsl:copy-of select="$ROInfo"/>
            </dct:publisher>
          </xsl:when>
        </xsl:choose>
        <xsl:if
          test="$role = 'pointOfContact' and name(..) = 'gmd:contact' and count(//gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = ('custodian')]) = 0">
          <dct:publisher>
            <xsl:copy-of select="$ROInfo"/>
          </dct:publisher>
        </xsl:if>
      </xsl:when>

      <xsl:otherwise>
        <xsl:choose>
          <xsl:when test="$role = 'owner'">
            <dct:rightsHolder>
              <xsl:copy-of select="$ROInfo"/>
            </dct:rightsHolder>
          </xsl:when>
          <xsl:when test="$role = 'distributor'">
            <geodcat:distributor>
              <xsl:copy-of select="$ROInfo"/>
            </geodcat:distributor>
          </xsl:when>
          <xsl:when test="$role = 'pointOfContact'">
            <dcat:contactPoint>
              <xsl:copy-of select="$ResponsibleParty"/>
            </dcat:contactPoint>
          </xsl:when>
          <xsl:when test="$role = 'publisher'">
            <dct:publisher>
              <xsl:copy-of select="$ROInfo"/>
            </dct:publisher>
          </xsl:when>
          <xsl:when test="$role = 'author'">
            <dct:creator>
              <xsl:copy-of select="$ROInfo"/>
            </dct:creator>
          </xsl:when>
        </xsl:choose>
        <xsl:if test="$role = 'owner' and
                      count(../../gmd:pointOfContact/gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'publisher']) = 0 and
                      count(../preceding-sibling::gmd:pointOfContact[gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = 'owner']]) = 0">
          <dct:publisher>
            <xsl:copy-of select="$ROInfo"/>
          </dct:publisher>
        </xsl:if>
        <xsl:if
          test="$role = 'pointOfContact' and name(..) = 'gmd:contact' and count(//gmd:CI_ResponsibleParty/gmd:role/gmd:CI_RoleCode[@codeListValue = ('publisher', 'owner')]) = 0">
          <dct:publisher>
            <xsl:copy-of select="$ROInfo"/>
          </dct:publisher>
        </xsl:if>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Conformity -->
  <xsl:template name="Conformity"
                match="gmd:dataQualityInfo/*/gmd:report/*/gmd:result/*/gmd:specification/gmd:CI_Citation">
    <xsl:param name="MetadataLanguage"/>
    <xsl:if test="../../gmd:pass/gco:Boolean = 'true'">
      <xsl:choose>
        <xsl:when test="../@xlink:href and ../@xlink:href != ''">
          <dct:conformsTo rdf:resource="{geonet:escapeURI(../@xlink:href)}"/>
        </xsl:when>
        <xsl:otherwise>
          <dct:conformsTo>
            <dct:Standard>
              <dct:title xml:lang="{$MetadataLanguage}">
                <xsl:value-of select="geonet:getLabel(gmd:title)"/>
              </dct:title>
            </dct:Standard>
          </dct:conformsTo>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- Geographic identifier -->
  <xsl:template name="GeographicIdentifier"
                match="gmd:EX_GeographicDescription/gmd:geographicIdentifier/*">
    <xsl:param name="MetadataLanguage"/>
    <xsl:variable name="GeoCode">
      <xsl:choose>
        <xsl:when test="gmd:code/gco:CharacterString">
          <xsl:value-of select="gmd:code/gco:CharacterString"/>
        </xsl:when>
        <xsl:when test="gmd:code/gmx:Anchor">
          <xsl:value-of select="gmd:code/gmx:Anchor/@xlink:href"/>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="GeoURI">
      <xsl:if test="starts-with($GeoCode,'http://') or starts-with($GeoCode,'https://')">
        <xsl:value-of select="geonet:escapeURI($GeoCode)"/>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="GeoURN">
      <xsl:if test="starts-with($GeoCode,'urn:')">
        <xsl:value-of select="geonet:escapeURI($GeoCode)"/>
      </xsl:if>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$GeoURI != ''">
        <dct:spatial rdf:resource="{$GeoURI}"/>
      </xsl:when>
      <xsl:when test="$GeoCode != ''">
        <dct:spatial>
          <xsl:choose>
            <xsl:when test="$GeoURN != ''">
              <dct:identifier>
                <xsl:value-of select="$GeoURN"/>
              </dct:identifier>
            </xsl:when>
            <xsl:otherwise>
              <skos:prefLabel xml:lang="{$MetadataLanguage}">
                <xsl:value-of select="$GeoCode"/>
              </skos:prefLabel>
            </xsl:otherwise>
          </xsl:choose>
          <xsl:for-each select="gmd:authority/gmd:CI_Citation">
            <skos:inScheme>
              <skos:ConceptScheme>
                <dct:title xml:lang="{$MetadataLanguage}">
                  <xsl:value-of select="gmd:title/gco:CharacterString"/>
                </dct:title>
              </skos:ConceptScheme>
            </skos:inScheme>
          </xsl:for-each>
        </dct:spatial>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Geographic bounding box -->
  <xsl:template name="GeographicBoundingBox" match="gmd:EX_GeographicBoundingBox">
    <xsl:variable name="north" select="gmd:northBoundLatitude/gco:Decimal"/>
    <xsl:variable name="east" select="gmd:eastBoundLongitude/gco:Decimal"/>
    <xsl:variable name="south" select="gmd:southBoundLatitude/gco:Decimal"/>
    <xsl:variable name="west" select="gmd:westBoundLongitude/gco:Decimal"/>

    <xsl:variable name="GMLLiteral">
      <xsl:variable name="GMLValue">
        <xsl:choose>
          <xsl:when test="$SrsUri = 'http://www.opengis.net/def/crs/OGC/1.3/CRS84'">
            <xsl:value-of
              select="concat($north, ' ', $east, ' ', $south, ' ', $east, ' ', $south, ' ', $west, ' ', $north, ' ', $west, ' ', $north, ' ', $east)"/>
          </xsl:when>
          <xsl:when test="$SrsAxisOrder = 'LonLat'">
            <xsl:value-of
              select="concat($east, ' ', $north, ' ', $east, ' ', $south, ' ', $west, ' ', $south, ' ', $west, ' ', $north, ' ', $east, ' ', $north)"/>
          </xsl:when>
          <xsl:when test="$SrsAxisOrder = 'LatLon'">
            <xsl:value-of
              select="concat($north, ' ', $east, ' ', $south, ' ', $east, ' ', $south, ' ', $west, ' ', $north, ' ', $west, ' ', $north, ' ', $east)"/>
          </xsl:when>
        </xsl:choose>
      </xsl:variable>
      <xsl:if test="$GMLValue">
        <xsl:text>&lt;gml:Polygon&gt;&lt;gml:exterior&gt;&lt;gml:LinearRing&gt;&lt;gml:posList&gt;</xsl:text>
        <xsl:value-of select="$GMLValue"/>
        <xsl:text>&lt;/gml:posList&gt;&lt;/gml:LinearRing&gt;&lt;/gml:exterior&gt;&lt;/gml:Polygon&gt;</xsl:text>
      </xsl:if>
    </xsl:variable>
    <xsl:variable name="WKTLiteral">
      <xsl:choose>
        <xsl:when test="$SrsUri = 'http://www.opengis.net/def/crs/OGC/1.3/CRS84'">POLYGON((<xsl:value-of
          select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of
          select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of
          select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of
          select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of
          select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>))
        </xsl:when>
        <xsl:when test="$SrsAxisOrder = 'LonLat'">&lt;<xsl:value-of select="$SrsUri"/>&gt; POLYGON((<xsl:value-of
          select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of
          select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>,<xsl:value-of
          select="$east"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of
          select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$south"/>,<xsl:value-of
          select="$west"/><xsl:text> </xsl:text><xsl:value-of select="$north"/>))
        </xsl:when>
        <xsl:when test="$SrsAxisOrder = 'LatLon'">&lt;<xsl:value-of select="$SrsUri"/>&gt; POLYGON((<xsl:value-of
          select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>,<xsl:value-of
          select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$east"/>,<xsl:value-of
          select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$east"/>,<xsl:value-of
          select="$south"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>,<xsl:value-of
          select="$north"/><xsl:text> </xsl:text><xsl:value-of select="$west"/>))
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="GeoJSONLiteral">
      {"type":"Polygon","crs":{"type":"name","properties":{"name":"<xsl:value-of select="$SrsUrn"/>"}},"coordinates":[[[<xsl:value-of
      select="$west"/><xsl:text>,</xsl:text><xsl:value-of select="$north"/>],[<xsl:value-of
      select="$east"/><xsl:text>,</xsl:text><xsl:value-of select="$north"/>],[<xsl:value-of
      select="$east"/><xsl:text>,</xsl:text><xsl:value-of select="$south"/>],[<xsl:value-of
      select="$west"/><xsl:text>,</xsl:text><xsl:value-of select="$south"/>],[<xsl:value-of
      select="$west"/><xsl:text>,</xsl:text><xsl:value-of select="$north"/>]]]}
    </xsl:variable>
    <dct:spatial>
      <dct:Location>
        <locn:geometry>
          <xsl:attribute name="rdf:datatype"
                         select="'https://www.iana.org/assignments/media-types/application/vnd.geo+json'"/>
          <xsl:value-of select="$GeoJSONLiteral"/>
        </locn:geometry>
        <locn:geometry>
          <xsl:attribute name="rdf:datatype"
                         select="'http://www.opengis.net/ont/geosparql#wktLiteral'"/>
          <xsl:value-of select="$WKTLiteral"/>
        </locn:geometry>
        <locn:geometry>
          <xsl:attribute name="rdf:datatype"
                         select="'http://www.opengis.net/ont/geosparql#gmlLiteral'"/>
          <xsl:value-of select="$GMLLiteral"/>
        </locn:geometry>
      </dct:Location>
    </dct:spatial>
  </xsl:template>

  <!-- Geographic extent -->
  <xsl:template name="GeographicExtent" mode="bbox" match="gmd:EX_GeographicBoundingBox">
    <xsl:variable name="north" select="gmd:northBoundLatitude/gco:Decimal"/>
    <xsl:variable name="east" select="gmd:eastBoundLongitude/gco:Decimal"/>
    <xsl:variable name="south" select="gmd:southBoundLatitude/gco:Decimal"/>
    <xsl:variable name="west" select="gmd:westBoundLongitude/gco:Decimal"/>
    <xsl:variable name="geoId"
                  select="normalize-space((../../gmd:geographicElement/gmd:EX_GeographicDescription/gmd:geographicIdentifier/gmd:MD_Identifier/gmd:code/gco:CharacterString)[1])"/>
    <dct:spatial>
      <dct:Location>
        <xsl:if test="$geoId != ''">
          <xsl:choose>
            <xsl:when test="starts-with($geoId, 'http://') or starts-with($geoId, 'https://')">
              <xsl:attribute name="rdf:about" select="$geoId"/>
            </xsl:when>
            <xsl:otherwise>
              <locn:geographicName xml:lang="nl">
                <xsl:value-of select="$geoId"/>
              </locn:geographicName>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:if>
        <dcat:bbox>
          <xsl:variable name="bbox">
            <gml:Envelope srsName="{$SrsUri}">
              <gml:lowerCorner>
                <xsl:value-of select="concat($west, ' ', $south)"/>
              </gml:lowerCorner>
              <gml:upperCorner>
                <xsl:value-of select="concat($east, ' ', $north)"/>
              </gml:upperCorner>
            </gml:Envelope>
          </xsl:variable>
          <xsl:apply-templates select="$bbox" mode="serialize"/>
        </dcat:bbox>
      </dct:Location>
    </dct:spatial>
  </xsl:template>

  <!-- Temporal extent -->
  <xsl:template name="TemporalExtent"
                match="gmd:identificationInfo/*/gmd:extent/gmd:EX_Extent/gmd:temporalElement/gmd:EX_TemporalExtent">
    <xsl:for-each
      select="gmd:extent/(gml:TimeInstant|gml320:TimeInstant)|gmd:extent/(gml:TimePeriod|gml320:TimePeriod)">
      <xsl:if
        test="local-name(.) = 'TimeInstant' or ( local-name(.) = 'TimePeriod' and (gml:beginPosition or gml320:beginPosition) and (gml:endPosition or gml320:endPosition) )">
        <xsl:variable name="dateStart">
          <xsl:choose>
            <xsl:when test="local-name(.) = 'TimeInstant'">
              <xsl:value-of select="gml:timePosition|gml320:timePosition"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="gml:beginPosition|gml320:beginPosition"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:variable name="dateEnd">
          <xsl:choose>
            <xsl:when test="local-name(.) = 'TimeInstant'">
              <xsl:value-of select="gml:timePosition|gml320:timePosition"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:value-of select="gml:endPosition|gml320:endPosition"/>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <xsl:if test="normalize-space($dateStart) != '' or normalize-space($dateEnd) != ''">
          <dct:temporal>
            <dct:PeriodOfTime>
              <xsl:if test="normalize-space($dateStart) != ''">
                <dcat:startDate>
                  <xsl:value-of select="geonet:formatRdfDate($dateStart)"/>
                </dcat:startDate>
              </xsl:if>
              <xsl:if test="normalize-space($dateEnd) != ''">
                <dcat:endDate>
                  <xsl:value-of select="geonet:formatRdfDate($dateEnd)"/>
                </dcat:endDate>
              </xsl:if>
            </dct:PeriodOfTime>
          </dct:temporal>
        </xsl:if>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <!-- Generic date template -->
  <xsl:template name="Dates" match="gmd:date/gmd:CI_Date">
    <xsl:variable name="date" select="normalize-space(geonet:formatRdfDate(gmd:date/*))"/>
    <xsl:variable name="type" select="gmd:dateType/gmd:CI_DateTypeCode/@codeListValue"/>
    <xsl:if test="$date != ''">
      <xsl:choose>
        <xsl:when test="$type = 'publication'">
          <dct:issued>
            <xsl:value-of select="$date"/>
          </dct:issued>
        </xsl:when>
        <xsl:when test="$type = 'revision'">
          <dct:modified>
            <xsl:value-of select="$date"/>
          </dct:modified>
        </xsl:when>
        <xsl:when test="$type = 'creation'">
          <dct:created>
            <xsl:value-of select="$date"/>
          </dct:created>
        </xsl:when>
      </xsl:choose>
    </xsl:if>
  </xsl:template>

  <!-- Keyword -->
  <xsl:template name="Keyword"
                match="gmd:identificationInfo/*/gmd:descriptiveKeywords/gmd:MD_Keywords">
    <xsl:param name="MetadataLanguage"/>
    <xsl:variable name="OriginatingControlledVocabulary">
      <xsl:for-each select="gmd:thesaurusName/gmd:CI_Citation">
        <xsl:for-each select="gmd:title">
          <dct:title xml:lang="{$MetadataLanguage}">
            <xsl:value-of select="normalize-space(gco:CharacterString|gmx:Anchor)"/>
          </dct:title>
          <xsl:call-template name="LocalisedString">
            <xsl:with-param name="term">dct:title</xsl:with-param>
          </xsl:call-template>
        </xsl:for-each>
      </xsl:for-each>
    </xsl:variable>
    <xsl:variable name="firstThesaurus" select="gmd:thesaurusName/gmd:CI_Citation/gmd:title[1]"/>
    <xsl:variable name="thesaurusIdentifier">
      <xsl:choose>
        <xsl:when test="$firstThesaurus/gmx:Anchor">
          <xsl:value-of select="string($firstThesaurus/gmx:Anchor/@xlink:href)"/>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="normalize-space($firstThesaurus/gco:CharacterString)"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="scheme">
      <xsl:choose>
        <xsl:when test="normalize-space($firstThesaurus/gco:CharacterString) != ''">
          <xsl:call-template name="GetSchemeFromThesaurusTitle">
            <xsl:with-param name="thesaurusTitle" select="$thesaurusIdentifier"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$thesaurusIdentifier"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:for-each select="gmd:keyword">
      <xsl:variable name="keywordAbout">
        <xsl:choose>
          <xsl:when test="gco:CharacterString">
            <xsl:call-template name="GetAboutFromCharacterString">
              <xsl:with-param name="keyword" select="normalize-space(gco:CharacterString)"/>
              <xsl:with-param name="thesaurusIdentifier" select="$thesaurusIdentifier"/>
              <xsl:with-param name="lang" select="$MetadataLanguage"/>
            </xsl:call-template>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="geonet:escapeURI(gmx:Anchor/@xlink:href)"/>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:variable>

      <xsl:choose>
        <!-- Keywords not originating from any vocabulary -->
        <xsl:when test="normalize-space($keywordAbout) = ''">
          <xsl:if test="normalize-space(gco:CharacterString|gmx:Anchor) != ''">
            <dcat:keyword xml:lang="{$MetadataLanguage}">
              <xsl:value-of select="normalize-space(gco:CharacterString|gmx:Anchor)"/>
            </dcat:keyword>
          </xsl:if>
          <xsl:call-template name="LocalisedString">
            <xsl:with-param name="term">dcat:keyword</xsl:with-param>
          </xsl:call-template>
        </xsl:when>

        <!--Keyword originating from a controlled vocabulary -->
        <xsl:otherwise>
          <xsl:variable name="concept">
            <skos:Concept>
              <xsl:attribute name="rdf:about" select="geonet:escapeURI($keywordAbout)"/>
              <skos:prefLabel xml:lang="{$MetadataLanguage}">
                <xsl:value-of select="normalize-space(gco:CharacterString|gmx:Anchor)"/>
              </skos:prefLabel>
              <xsl:call-template name="LocalisedString">
                <xsl:with-param name="term">skos:prefLabel</xsl:with-param>
              </xsl:call-template>
              <skos:inScheme>
                <xsl:choose>
                  <xsl:when test="normalize-space($scheme) != ''">
                    <xsl:attribute name="rdf:resource" select="normalize-space($scheme)"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <skos:ConceptScheme>
                      <xsl:copy-of select="$OriginatingControlledVocabulary"/>
                    </skos:ConceptScheme>
                  </xsl:otherwise>
                </xsl:choose>
              </skos:inScheme>
            </skos:Concept>
          </xsl:variable>
          <xsl:variable name="property">
            <xsl:choose>
              <xsl:when test="geonet:urlEquals($scheme, 'vocab.belgif.be/auth/datatheme')">
                <xsl:value-of select="'dcat:theme'"/>
              </xsl:when>
              <xsl:when
                test="geonet:urlEquals($scheme, 'inspire.ec.europa.eu/metadata-codelist/TopicCategory')">
                <xsl:value-of select="'mdcat:ISO-categorie'"/>
              </xsl:when>
              <xsl:when test="geonet:urlEquals($scheme, 'inspire.ec.europa.eu/theme')">
                <xsl:value-of select="'mdcat:INSPIRE-thema'"/>
              </xsl:when>
              <xsl:when test="geonet:urlEquals($scheme, 'www.eionet.europa.eu/gemet')">
                <xsl:value-of select="'mdcat:GEMET-concept'"/>
              </xsl:when>
              <xsl:when
                test="geonet:urlEquals($scheme, 'data.vlaanderen.be/id/conceptscheme/MAGDA-categorie')">
                <xsl:value-of select="'mdcat:MAGDA-categorie'"/>
              </xsl:when>
              <xsl:when
                test="geonet:urlEquals($scheme, 'metadata.vlaanderen.be/id/GDI-Vlaanderen-Trefwoorden')">
                <xsl:value-of select="'mdcat:statuut'"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:value-of select="'dct:subject'"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:variable>
          <xsl:if test="normalize-space($property) != ''">
            <xsl:element name="{$property}">
              <xsl:copy-of select="$concept"/>
            </xsl:element>
          </xsl:if>
        </xsl:otherwise>
      </xsl:choose>

      <!-- Map topic categories to themes -->
      <xsl:if
        test="geonet:urlEquals($scheme, 'inspire.ec.europa.eu/metadata-codelist/TopicCategory') and gmx:Anchor/@xlink:href">
        <xsl:variable name="topic"
                      select="substring-after(gmx:Anchor/@xlink:href, 'inspire.ec.europa.eu/metadata-codelist/TopicCategory/')"/>
        <xsl:call-template name="MapTopicCatToDataGovTheme">
          <xsl:with-param name="TopicCategory" select="$topic"/>
        </xsl:call-template>
      </xsl:if>

    </xsl:for-each>
  </xsl:template>

  <!-- Alternate title -->
  <xsl:template name="AlternateTitle" match="gmd:alternateTitle">
    <xsl:param name="MetadataLanguage"/>
    <xsl:if test="normalize-space(gco:CharacterString|gmx:Anchor) != ''">
      <dcat:keyword xml:lang="{if ($MetadataLanguage != '') then $MetadataLanguage else 'nl'}">
        <xsl:value-of select="normalize-space(gco:CharacterString|gmx:Anchor)"/>
      </dcat:keyword>
    </xsl:if>
  </xsl:template>

  <!-- Conforms to - Feature catalog description -->
  <xsl:template name="FeatureCatalogueDescription"
                match="gmd:contentInfo/gmd:MD_FeatureCatalogueDescription">
    <xsl:for-each select="gmd:featureCatalogueCitation[normalize-space(@uuidref) != '']">
      <dct:conformsTo>
        <dct:Standard>
          <xsl:variable name="uuidref" select="@uuidref"/>
          <xsl:choose>
            <xsl:when test="normalize-space(@xlink:href) != ''">
              <xsl:attribute name="rdf:about" select="@xlink:href"/>
            </xsl:when>
            <xsl:otherwise>
              <xsl:attribute name="rdf:about" select="concat(
                $catalogUrl,
                '/csw?service=CSW&amp;request=GetRecordById&amp;version=2.0.2&amp;outputSchema=http://www.isotc211.org/2005/gmd&amp;elementSetName=full&amp;id=',
                $uuidref
              )"/>
            </xsl:otherwise>
          </xsl:choose>

          <xsl:variable name="title" select="geonet:getLabel(gmd:CI_Citation/gmd:title)"/>
          <xsl:if test="$title != ''">
            <dct:title>
              <xsl:value-of select="$title"/>
            </dct:title>
          </xsl:if>
          <xsl:apply-templates select="gmd:CI_Citation/gmd:edition"/>
          <xsl:apply-templates select="gmd:CI_Citation/gmd:date/gmd:CI_Date"/>
          <dct:type rdf:resource="https://www.iso.org/standard/39965.html"/>
          <!-- <dct:type rdf:resource="https://www.iso.org/standard/57303.html"/> -->
        </dct:Standard>
      </dct:conformsTo>
    </xsl:for-each>
  </xsl:template>

  <!-- Reference system info -->
  <xsl:template name="ReferenceSystemInfo" match="gmd:referenceSystemInfo">
    <xsl:variable name="code"
                  select="gmd:MD_ReferenceSystem/gmd:referenceSystemIdentifier/gmd:RS_Identifier/gmd:code"/>
    <xsl:variable name="crs"
                  select="string($code/gmx:Anchor/@xlink:href|$code/gco:CharacterString)"/>

    <xsl:variable name="crsTitle"
                  select="normalize-space($code/gmx:Anchor|$code/gco:CharacterString)"/>
    <xsl:choose>
      <xsl:when test="starts-with($crs, 'http://') or starts-with($crs, 'https://')">
        <dct:conformsTo>
          <dct:Standard>
            <xsl:attribute name="rdf:about" select="$crs"/>
            <xsl:if test="$crsTitle != ''">
              <dct:title>
                <xsl:value-of select="$crsTitle"/>
              </dct:title>
            </xsl:if>
            <dct:type rdf:resource="http://inspire.ec.europa.eu/glossary/SpatialReferenceSystem"/>
          </dct:Standard>
        </dct:conformsTo>
      </xsl:when>
      <xsl:otherwise>
        <dct:conformsTo>
          <dct:Standard>
            <dct:identifier>
              <xsl:value-of select="$crs"/>
            </dct:identifier>
            <xsl:if test="$crsTitle != ''">
              <dct:title>
                <xsl:value-of select="$crsTitle"/>
              </dct:title>
            </xsl:if>
            <dct:type rdf:resource="http://inspire.ec.europa.eu/glossary/SpatialReferenceSystem"/>
          </dct:Standard>
        </dct:conformsTo>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Topic category -->
  <xsl:template name="TopicCategory" match="gmd:identificationInfo/*/gmd:topicCategory">
    <xsl:variable name="TopicCategory" select="normalize-space(gmd:MD_TopicCategoryCode)"/>
    <xsl:variable name="DataGovTheme">
      <xsl:call-template name="MapTopicCatToDataGovTheme">
        <xsl:with-param name="TopicCategory" select="$TopicCategory"/>
      </xsl:call-template>
    </xsl:variable>

    <xsl:choose>
      <xsl:when test="$DataGovTheme/dcat:theme">

        <xsl:variable name="alreadyAddedGovThemes">
          <xsl:for-each select="../gmd:descriptiveKeywords/gmd:MD_Keywords[gmd:thesaurusName/gmd:CI_Citation/gmd:title[1]/gmx:Anchor/@xlink:href = (
            'http://vocab.belgif.be/auth/datatheme',
            'http://vocab.belgif.be/auth/datatheme/',
            'https://vocab.belgif.be/auth/datatheme',
            'https://vocab.belgif.be/auth/datatheme/'
          )]">
            <xsl:for-each select="gmd:keyword/gmx:Anchor">
              <theme>
                <xsl:value-of select="string(@xlink:href)"/>
              </theme>
            </xsl:for-each>
          </xsl:for-each>

          <xsl:for-each select="../gmd:descriptiveKeywords/gmd:MD_Keywords[gmd:thesaurusName/gmd:CI_Citation/gmd:title[1]/gmx:Anchor/@xlink:href = (
            'http://inspire.ec.europa.eu/metadata-codelist/TopicCategory',
            'http://inspire.ec.europa.eu/metadata-codelist/TopicCategory/',
            'https://inspire.ec.europa.eu/metadata-codelist/TopicCategory',
            'https://inspire.ec.europa.eu/metadata-codelist/TopicCategory/'
          )]">
            <xsl:for-each select="gmd:keyword/gmx:Anchor">
              <xsl:variable name="topic" select="if (starts-with(@xlink:href, 'https'))
                                             then substring-after(@xlink:href, 'https://inspire.ec.europa.eu/metadata-codelist/TopicCategory/')
                                             else substring-after(@xlink:href, 'http://inspire.ec.europa.eu/metadata-codelist/TopicCategory/')"/>
              <xsl:variable name="theme">
                <xsl:call-template name="MapTopicCatToDataGovTheme">
                  <xsl:with-param name="TopicCategory" select="$topic"/>
                </xsl:call-template>
              </xsl:variable>
              <theme>
                <xsl:value-of select="string($theme//skos:Concept/@rdf:about)"/>
              </theme>
            </xsl:for-each>
          </xsl:for-each>

          <xsl:for-each select="preceding-sibling::gmd:topicCategory">
            <xsl:variable name="mapped">
              <xsl:call-template name="MapTopicCatToDataGovTheme">
                <xsl:with-param name="TopicCategory"
                                select="normalize-space(gmd:MD_TopicCategoryCode)"/>
              </xsl:call-template>
            </xsl:variable>
            <xsl:if test="$mapped/dcat:theme">
              <theme>
                <xsl:value-of select="string($mapped/dcat:theme/skos:Concept/@rdf:about)"/>
              </theme>
            </xsl:if>
          </xsl:for-each>
        </xsl:variable>

        <xsl:if
          test="count($alreadyAddedGovThemes/theme[. = $DataGovTheme/dcat:theme/skos:Concept/@rdf:about]) = 0">
          <xsl:copy-of select="$DataGovTheme"/>
        </xsl:if>
      </xsl:when>
      <xsl:when test="$TopicCategory != ''">
        <dct:subject rdf:resource="{$TopicCategoryCodelistUri}/{$TopicCategory}"/>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Character encoding -->
  <xsl:template name="CharacterEncoding" match="gmd:characterSet/gmd:MD_CharacterSetCode">
    <xsl:variable name="CharSetCode">
      <xsl:choose>
        <xsl:when test="@codeListValue = 'ucs2'">
          <xsl:text>ISO-10646-UCS-2</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'ucs4'">
          <xsl:text>ISO-10646-UCS-4</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'utf7'">
          <xsl:text>UTF-7</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'utf8'">
          <xsl:text>UTF-8</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'utf16'">
          <xsl:text>UTF-16</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part1'">
          <xsl:text>ISO-8859-1</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part2'">
          <xsl:text>ISO-8859-2</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part3'">
          <xsl:text>ISO-8859-3</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part4'">
          <xsl:text>ISO-8859-4</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part5'">
          <xsl:text>ISO-8859-5</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part6'">
          <xsl:text>ISO-8859-6</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part7'">
          <xsl:text>ISO-8859-7</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part8'">
          <xsl:text>ISO-8859-8</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part9'">
          <xsl:text>ISO-8859-9</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part10'">
          <xsl:text>ISO-8859-10</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part11'">
          <xsl:text>ISO-8859-11</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part12'">
          <xsl:text>ISO-8859-12</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part13'">
          <xsl:text>ISO-8859-13</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part14'">
          <xsl:text>ISO-8859-14</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part15'">
          <xsl:text>ISO-8859-15</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = '8859part16'">
          <xsl:text>ISO-8859-16</xsl:text>
        </xsl:when>
        <!-- Mapping to be verified: multiple candidates are available in the IANA register for jis -->
        <xsl:when test="@codeListValue = 'jis'">
          <xsl:text>JIS_Encoding</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'shiftJIS'">
          <xsl:text>Shift_JIS</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'eucJP'">
          <xsl:text>EUC-JP</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'usAscii'">
          <xsl:text>US-ASCII</xsl:text>
        </xsl:when>
        <!-- Mapping to be verified: multiple candidates are available in the IANA register ebcdic  -->
        <xsl:when test="@codeListValue = 'ebcdic'">
          <xsl:text>IBM037</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'eucKR'">
          <xsl:text>EUC-KR</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'big5'">
          <xsl:text>Big5</xsl:text>
        </xsl:when>
        <xsl:when test="@codeListValue = 'GB2312'">
          <xsl:text>GB2312</xsl:text>
        </xsl:when>
      </xsl:choose>
    </xsl:variable>
    <cnt:characterEncoding>
      <xsl:value-of select="$CharSetCode"/>
    </cnt:characterEncoding>
  </xsl:template>

  <!-- Encoding -->
  <xsl:template name="Encoding" match="gmd:distributionFormat/gmd:MD_Format/gmd:name/*">
    <xsl:choose>
      <xsl:when test="@xlink:href and @xlink:href != ''">
        <xsl:call-template name="Fill-format-concept-from-uri">
          <xsl:with-param name="formatUri" select="geonet:escapeURI(@xlink:href)"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="mappedFormat">
          <xsl:call-template name="Map-format-to-file-type">
            <xsl:with-param name="format" select="."/>
          </xsl:call-template>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$mappedFormat/count(*) > 0">
            <xsl:copy-of select="$mappedFormat/dct:format"/>
          </xsl:when>
          <xsl:when test="normalize-space(.) != ''">
            <dct:format>
              <skos:Concept>
                <rdf:type rdf:resource="http://purl.org/dc/terms/MediaTypeOrExtent"/>
                <skos:prefLabel>
                  <xsl:value-of select="."/>
                </skos:prefLabel>
              </skos:Concept>
            </dct:format>
          </xsl:when>
        </xsl:choose>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <!-- Maintenance information -->
  <xsl:template name="MaintenanceInformation"
                match="gmd:MD_MaintenanceInformation/gmd:maintenanceAndUpdateFrequency/gmd:MD_MaintenanceFrequencyCode">
    <!-- The following parameter maps frequency codes used in ISO 19139 metadata to the corresponding ones of the Dublin Core Collection Description Frequency Vocabulary (when available). -->
    <xsl:variable name="FrequencyCodeURI">
      <xsl:if test="@codeListValue != ''">
        <xsl:choose>
          <xsl:when test="@codeListValue = 'continual'">
            <xsl:value-of select="concat($opfq,'CONT')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'daily'">
            <xsl:value-of select="concat($opfq,'DAILY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'weekly'">
            <xsl:value-of select="concat($opfq,'WEEKLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'fortnightly'">
            <xsl:value-of select="concat($opfq,'BIWEEKLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'monthly'">
            <xsl:value-of select="concat($opfq,'MONTHLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'quarterly'">
            <xsl:value-of select="concat($opfq,'QUARTERLY')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'biannually'">
            <xsl:value-of select="concat($opfq,'ANNUAL_2')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'annually'">
            <xsl:value-of select="concat($opfq,'ANNUAL')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'asNeeded'">
            <!--  A mapping is missing in Dublin Core and MDR Freq NAL-->
            <xsl:value-of select="concat($MaintenanceFrequencyCodelistUri,'/',@codeListValue)"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'irregular'">
            <xsl:value-of select="concat($opfq,'IRREG')"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'notPlanned'">
            <!--  A mapping is missing in Dublin Core and MDR Freq NAL -->
            <xsl:value-of select="concat($MaintenanceFrequencyCodelistUri,'/',@codeListValue)"/>
          </xsl:when>
          <xsl:when test="@codeListValue = 'unknown'">
            <!--  A mapping is missing in Dublin Core -->
            <xsl:value-of select="concat($opfq,'UNKNOWN')"/>
          </xsl:when>
        </xsl:choose>
      </xsl:if>
    </xsl:variable>
    <xsl:if test="$FrequencyCodeURI != ''">
      <dct:accrualPeriodicity rdf:resource="{geonet:escapeURI($FrequencyCodeURI)}"/>
    </xsl:if>
  </xsl:template>

  <!-- Spatial representation type (tentative) -->
  <xsl:template name="SpatialRepresentationType"
                match="gmd:identificationInfo/*/gmd:spatialRepresentationType/gmd:MD_SpatialRepresentationTypeCode">
    <adms:representationTechnique>
      <skos:Concept rdf:about="{$SpatialRepresentationTypeCodelistUri}/{@codeListValue}">
        <skos:notation>
          <xsl:value-of
            select="'het primaire ruimtelijke voorstellingstype waarin de data in de dataset wordt beheerd'"/>
        </skos:notation>
        <skos:inScheme rdf:resource="{$SpatialRepresentationTypeCodelistUri}"/>
      </skos:Concept>
    </adms:representationTechnique>
  </xsl:template>

  <!-- Spatial resolution -->
  <xsl:template name="SpatialResolution" match="gmd:identificationInfo/*/gmd:spatialResolution">
    <xsl:choose>
      <xsl:when test="gmd:MD_Resolution/gmd:distance/gco:Distance[@uom != '']">
        <xsl:variable name="meters">
          <xsl:choose>
            <xsl:when
              test="gmd:MD_Resolution/gmd:distance/gco:Distance[@uom = ('mm', 'millimetre', 'millimetres')]">
              <xsl:value-of select="number(gmd:MD_Resolution/gmd:distance/gco:Distance) div 1000"/>
            </xsl:when>
            <xsl:when
              test="gmd:MD_Resolution/gmd:distance/gco:Distance[@uom = ('cm', 'centimeter', 'centimeters')]">
              <xsl:value-of select="number(gmd:MD_Resolution/gmd:distance/gco:Distance) div 100"/>
            </xsl:when>
            <xsl:when
              test="gmd:MD_Resolution/gmd:distance/gco:Distance[@uom = ('m', 'meter', 'meters')]">
              <xsl:value-of select="string(gmd:MD_Resolution/gmd:distance/gco:Distance)"/>
            </xsl:when>
            <xsl:when
              test="gmd:MD_Resolution/gmd:distance/gco:Distance[@uom = ('km', 'kilometer', 'kilometers')]">
              <xsl:value-of select="number(gmd:MD_Resolution/gmd:distance/gco:Distance) * 1000"/>
            </xsl:when>
          </xsl:choose>
        </xsl:variable>

        <xsl:if test="normalize-space($meters) != ''">
          <dcat:spatialResolutionInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">
            <xsl:value-of select="$meters"/>
          </dcat:spatialResolutionInMeters>
        </xsl:if>

        <dqv:hasQualityMeasurement>
          <dqv:QualityMeasurement>
            <dqv:isMeasurementOf>
              <dqv:Metric rdf:about="http://data.europa.eu/930/spatialResolutionAsDistance">
                <skos:prefLabel xml:lang="en">Spatial resolution as distance</skos:prefLabel>
                <dqv:expectedDataType rdf:resource="http://www.w3.org/2001/XMLSchema#decimal"/>
                <dqv:inDimension rdf:resource="http://www.w3.org/ns/dqv#precision"/>
              </dqv:Metric>
            </dqv:isMeasurementOf>
            <xsl:call-template name="Map-uom">
              <xsl:with-param name="uom" select="gmd:MD_Resolution/gmd:distance/gco:Distance/@uom"/>
            </xsl:call-template>
            <dqv:value rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">
              <xsl:value-of select="number(gmd:MD_Resolution/gmd:distance/gco:Distance)"/>
            </dqv:value>
          </dqv:QualityMeasurement>
        </dqv:hasQualityMeasurement>
      </xsl:when>
      <xsl:when
        test="gmd:MD_Resolution/gmd:equivalentScale/gmd:MD_RepresentativeFraction/gmd:denominator">
        <dqv:hasQualityMeasurement>
          <dqv:QualityMeasurement>
            <dqv:isMeasurementOf>
              <dqv:Metric rdf:about="http://data.europa.eu/930/spatialResolutionAsScale">
                <skos:prefLabel xml:lang="en">Spatial resolution as equivalent scale
                </skos:prefLabel>
                <dqv:expectedDataType rdf:resource="http://www.w3.org/2001/XMLSchema#decimal"/>
                <dqv:inDimension rdf:resource="http://www.w3.org/ns/dqv#precision"/>
              </dqv:Metric>
            </dqv:isMeasurementOf>
            <dqv:value rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">
              <xsl:value-of
                select="1 div number(gmd:MD_Resolution/gmd:equivalentScale/gmd:MD_RepresentativeFraction/gmd:denominator/*)"/>
            </dqv:value>
          </dqv:QualityMeasurement>
        </dqv:hasQualityMeasurement>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

  <!-- Version info -->
  <xsl:template name="VersionInfo" match="gmd:edition">
    <xsl:variable name="label" select="normalize-space(geonet:getLabel(.))"/>
    <xsl:if test="$label != ''">
      <owl:versionInfo>
        <xsl:value-of select="$label"/>
      </owl:versionInfo>
    </xsl:if>
  </xsl:template>

  <!-- Progress code -->
  <xsl:template name="ProgressCode"
                match="gmd:status/gmd:MD_ProgressCode[ends-with(@codeList,'#MD_ProgressCode')]">
    <xsl:variable name="scheme"
                  select="'http://standards.iso.org/iso/19139/resources/gmxCodelists.xml#MD_ProgressCode'"/>
    <xsl:variable name="uri" select="concat($scheme, '_', normalize-space(@codeListValue))"/>
    <xsl:variable name="concept" select="$ProgressCodeCodelist//skos:Concept[@rdf:about = $uri]"/>

    <xsl:if test="normalize-space($concept) != ''">
      <mdcat:status>
        <xsl:copy-of copy-namespaces="no" select="$concept"/>
      </mdcat:status>
    </xsl:if>
  </xsl:template>

  <!-- Multilingual text -->
  <xsl:template name="LocalisedString">
    <xsl:param name="term"/>
    <xsl:for-each select="gmd:PT_FreeText/*/gmd:LocalisedCharacterString">
      <xsl:variable name="value" select="normalize-space(.)"/>
      <xsl:variable name="langs">
        <xsl:call-template name="Alpha3-to-Alpha2">
          <xsl:with-param name="lang"
                          select="translate(lower-case(@locale), '#', '')"/>
        </xsl:call-template>
      </xsl:variable>
      <xsl:if test="$value != ''">
        <xsl:element name="{$term}">
          <xsl:attribute name="xml:lang">
            <xsl:value-of select="$langs"/>
          </xsl:attribute>
          <xsl:value-of select="$value"/>
        </xsl:element>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>

  <xsl:function name="geonet:formatRdfDate">
    <xsl:param name="date"/>
    <xsl:choose>
      <!-- xs:date -->
      <xsl:when test="matches($date, '^-?\d{4}-\d{2}-\d{2}(Z|(-|\+)\d{2}:\d{2})?$')">
        <!-- <xsl:variable name="timezone" select="normalize-space(format-date($date, '[Z]'))" /> -->
        <xsl:value-of select="format-date($date, '[Y0001]-[M01]-[D01]')"/>
      </xsl:when>

      <!-- xs:dateTime -->
      <xsl:when
        test="matches($date, '^-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?(Z|(-|\+)\d{2}:\d{2})?$')">
        <!-- <xsl:variable name="timezone" select="normalize-space(format-dateTime($date, '[Z]'))" /> -->
        <!-- <xsl:value-of select="format-dateTime($date, '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]')"/> -->
        <xsl:value-of select="format-dateTime($date, '[Y0001]-[M01]-[D01]')"/>
      </xsl:when>

      <!-- xs:gYearMonth -->
      <!-- <xsl:when test="matches($date, '^\d{4}-\d{2}$')"> -->
      <!--   <xsl:value-of select="string($date)"/> -->
      <!-- </xsl:when> -->

      <!-- xs:gYear -->
      <!-- <xsl:when test="matches($date, '^\d{4}$')"> -->
      <!--   <xsl:value-of select="string($date)"/> -->
      <!-- </xsl:when> -->
    </xsl:choose>
  </xsl:function>
</xsl:stylesheet>