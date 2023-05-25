<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:skos="http://www.w3.org/2004/02/skos/core#"
  xmlns:vcard="http://www.w3.org/2006/vcard/ns#"
  xmlns:foaf="http://xmlns.com/foaf/0.1/"
  xmlns:dcat="http://www.w3.org/ns/dcat#"
  xmlns:dct="http://purl.org/dc/terms/"
  xmlns:xml="http://www.w3.org/XML/1998/namespace"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:output method="xml"
              encoding="utf-8"/>

  <xsl:variable name="env" as="node()">
    <env>
      <system>
        <site>
          <siteId>ABC</siteId>
          <name>name</name>
          <organization>organization</organization>
          <organizationMail>organizationMail</organizationMail>
          <organizationUrl>organizationUrl</organizationUrl>
        </site>
      </system>
    </env>
  </xsl:variable>

  <xsl:variable name="iso2letterLanguageCode"
                select="'nl'"
                as="xs:string"/>

  <xsl:variable name="serviceUrl"
                select="'http://abc'"
                as="xs:string"/>

  <xsl:variable name="resourcePrefix"
                select="'http://abc'"
                as="xs:string"/>

  <xsl:template name="langId2toAuth">
    <xsl:param name="langId-2char"/>
    <xsl:choose>
      <xsl:when test="ends-with($langId-2char,'nl')">nld</xsl:when>
      <xsl:when test="ends-with($langId-2char,'fr')">fre</xsl:when>
      <xsl:when test="ends-with($langId-2char,'en')">eng</xsl:when>
      <xsl:when test="ends-with($langId-2char,'de')">deu</xsl:when>
      <xsl:otherwise><xsl:message select="concat('No mapping found in langId2toAuth for langId-2char with value ', $langId-2char)"/></xsl:otherwise>
    </xsl:choose>
  </xsl:template>


  <xsl:template match="/">
    <dcat:Catalog rdf:about="{$resourcePrefix}/catalogs/{$env/system/site/siteId}">

      <!-- A name given to the catalog. -->
      <!-- TODO
      No idea why the xml:lang attribute is not in the output
      and is replaced by the element name.
          <dct:title xmlns:dct="http://purl.org/dc/terms/" dct:title="nl">name</dct:title>
      -->
      <dct:title xml:lang="{$iso2letterLanguageCode}">
        <xsl:value-of select="$env/system/site/name"/>
      </dct:title>

      <!-- free-text account of the catalog. -->
      <dct:description xml:lang="{$iso2letterLanguageCode}">
        <xsl:value-of
          select="concat($env/system/site/name, ' (', $env/system/site/organization, ')')"/>
      </dct:description>

      <!-- Unique identifier of the catalog -->
      <dct:identifier>
        <xsl:value-of select="$env/system/site/siteId"/>
      </dct:identifier>
      <!-- The entity responsible for making the catalog online. -->
      <dct:publisher>
        <!-- Organization in charge of the catalogue defined in the administration > system configuration -->
        <foaf:Agent
          rdf:about="{$resourcePrefix}/organizations/{encode-for-uri($env/system/site/organization)}">
          <foaf:name xml:lang="{$iso2letterLanguageCode}">
            <xsl:value-of select="$env/system/site/organization"/>
          </foaf:name>
          <dct:type>
            <skos:Concept rdf:about="http://purl.org/adms/publishertype/LocalAuthority">
              <skos:prefLabel xml:lang="nl">Lokaal bestuur</skos:prefLabel>
              <skos:prefLabel xml:lang="en">Local Authority</skos:prefLabel>
              <skos:prefLabel xml:lang="fr">Local Authority</skos:prefLabel>
              <skos:prefLabel xml:lang="de">Local Authority</skos:prefLabel>
              <skos:inScheme rdf:resource="http://purl.org/adms/publishertype/1.0"/>
            </skos:Concept>
          </dct:type>
        </foaf:Agent>
      </dct:publisher>

      <!-- The homepage of the catalog -->
      <foaf:homepage>
        <foaf:Document>
          <xsl:if test="normalize-space($serviceUrl) != ''">
            <xsl:attribute name="rdf:about" select="$serviceUrl"/>
          </xsl:if>
          <foaf:name xml:lang="{$iso2letterLanguageCode}">
            <xsl:value-of select="$env/system/site/name"/>
          </foaf:name>
        </foaf:Document>
      </foaf:homepage>

      <!-- The license of the catalog -->
      <dct:license>
        <dct:LicenseDocument
          rdf:about="https://data.vlaanderen.be/id/licentie/creative-commons-zero-verklaring/v1.0">
          <dct:type>
            <skos:Concept rdf:about="http://purl.org/adms/licencetype/PublicDomain">
              <skos:prefLabel xml:lang="nl">Werk in het publiek domein</skos:prefLabel>
              <skos:prefLabel xml:lang="en">Public domain</skos:prefLabel>
              <skos:prefLabel xml:lang="fr">Public domain</skos:prefLabel>
              <skos:prefLabel xml:lang="de">Public domain</skos:prefLabel>
              <skos:inScheme rdf:resource="http://purl.org/adms/licencetype/1.0"/>
            </skos:Concept>
          </dct:type>
          <dct:title xml:lang="nl">Creative Commons Zero verklaring</dct:title>
          <dct:description xml:lang="nl">De instantie doet afstand van haar intellectuele
            eigendomsrechten voor zover dit wettelijk mogelijk is. Hierdoor kan de gebruiker de data
            hergebruiken voor eender welk doel, zonder een verplichting op naamsvermelding. Deze is
            de
            welbekende CC0 licentie.
          </dct:description>
          <dct:identifier>https://data.vlaanderen.be/id/licentie/creative-commons-zero-verklaring/v1.0
          </dct:identifier>
        </dct:LicenseDocument>
      </dct:license>
      <xsl:variable name="langAuth">
        <xsl:call-template name="langId2toAuth">
          <xsl:with-param name="langId-2char" select="$iso2letterLanguageCode"/>
        </xsl:call-template>
      </xsl:variable>
      <dct:language>
        <skos:Concept
          rdf:about="http://publications.europa.eu/resource/authority/language/{upper-case($langAuth)}">
          <rdf:type rdf:resource="http://purl.org/dc/terms/LinguisticSystem"/>
          <skos:prefLabel xml:lang="nl">Nederlands</skos:prefLabel>
          <skos:prefLabel xml:lang="en">Dutch</skos:prefLabel>
          <skos:prefLabel xml:lang="fr">néerlandais</skos:prefLabel>
          <skos:prefLabel xml:lang="de">Niederländisch</skos:prefLabel>
          <skos:inScheme rdf:resource="http://publications.europa.eu/resource/authority/language"/>
        </skos:Concept>
      </dct:language>
      <dcat:contactPoint>
        <vcard:Organization>
          <vcard:organization-name>
            <xsl:value-of select="$env/system/site/organization"/>
          </vcard:organization-name>
          <xsl:if test="normalize-space($env/system/site/organizationMail) != ''">
            <vcard:hasEmail
              rdf:resource="mailto:{normalize-space($env/system/site/organizationMail)}"/>
          </xsl:if>
          <xsl:if test="normalize-space($env/system/site/organizationUrl) != ''">
            <vcard:hasURL rdf:resource="{normalize-space($env/system/site/organizationUrl)}"/>
          </xsl:if>
        </vcard:Organization>
      </dcat:contactPoint>
    </dcat:Catalog>
  </xsl:template>
</xsl:stylesheet>
