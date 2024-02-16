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
  xmlns:geonet="http://www.fao.org/geonetwork"
  xmlns:xml="http://www.w3.org/XML/1998/namespace"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  exclude-result-prefixes="#all"
  version="3.0">

  <xsl:output method="xml"
              omit-xml-declaration="yes"
              indent="yes"
              encoding="utf-8"/>

  <xsl:include href="classpath:xslt/ogcapir/formats/dcat/dcat-iso19139.xsl"/>
  <xsl:include href="classpath:xslt/ogcapir/formats/dcat/dcat-dcat2-ap-vl.xsl"/>

  <xsl:variable name="env" as="node()">
    <env>
      <system>
        <site>
          <siteId>2a294fed-b38d-4c48-824f-098f9ec1d239</siteId>
          <name>Metadatacenter (van Digitaal Vlaanderen)</name>
          <organization>agentschap Digitaal Vlaanderen</organization>
          <organizationMail>digitaal.vlaanderen@vlaanderen.be</organizationMail>
          <organizationUrl>https://metadata.vlaanderen.be/metadatacenter</organizationUrl>
          <url>https://metadata.vlaanderen.be/metadatacenter</url>
        </site>
      </system>
    </env>
  </xsl:variable>

  <xsl:variable name="iso2letterLanguageCode"
                select="'nl'"
                as="xs:string"/>

  <xsl:variable name="resourcePrefix"
                select="'https://metadata.vlaanderen.be/srv/resources/'"
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


  <xsl:template match="/root">
    <rdf:RDF>
      <xsl:call-template name="add-namespaces"/>
      <xsl:call-template name="build-catalog"/>
      <xsl:apply-templates mode="dcat" select="records/*"/>
    </rdf:RDF>
  </xsl:template>

  <xsl:template name="add-namespaces">
    <xsl:namespace name="rdf" select="'http://www.w3.org/1999/02/22-rdf-syntax-ns#'"/>
    <xsl:namespace name="skos" select="'http://www.w3.org/2004/02/skos/core#'"/>
    <xsl:namespace name="spdx" select="'http://spdx.org/rdf/terms#'"/>
    <xsl:namespace name="owl" select="'http://www.w3.org/2002/07/owl#'"/>
    <xsl:namespace name="adms" select="'http://www.w3.org/ns/adms#'"/>
    <xsl:namespace name="locn" select="'http://www.w3.org/ns/locn#'"/>
    <xsl:namespace name="xsi" select="'http://www.w3.org/2001/XMLSchema-instance'"/>
    <xsl:namespace name="foaf" select="'http://xmlns.com/foaf/0.1/'"/>
    <xsl:namespace name="dct" select="'http://purl.org/dc/terms/'"/>
    <xsl:namespace name="vcard" select="'http://www.w3.org/2006/vcard/ns#'"/>
    <xsl:namespace name="dcat" select="'http://www.w3.org/ns/dcat#'"/>
    <xsl:namespace name="schema" select="'http://schema.org/'"/>
    <xsl:namespace name="dc" select="'http://purl.org/dc/elements/1.1/'"/>
    <xsl:namespace name="dqv" select="'http://www.w3.org/ns/dqv#'"/>
    <xsl:namespace name="sdmx-attribute" select="'http://purl.org/linked-data/sdmx/2009/attribute#'"/>
    <xsl:namespace name="prov" select="'http://www.w3.org/ns/prov#'"/>
    <xsl:namespace name="qudt" select="'http://qudt.org/schema/qudt/'"/>
    <xsl:namespace name="rdfs" select="'http://www.w3.org/2000/01/rdf-schema#'"/>
    <xsl:namespace name="vaem" select="'http://www.linkedmodel.org/schema/vaem#'"/>
    <xsl:namespace name="cnt" select="'http://www.w3.org/2011/content#'"/>
    <xsl:namespace name="mdcat" select="'https://data.vlaanderen.be/ns/metadata-dcat#'"/>
    <xsl:namespace name="vlgen" select="'https://data.vlaanderen.be/ns/generiek'"/>
    <xsl:namespace name="adres" select="'https://data.vlaanderen.be/ns/adres#'"/>
  </xsl:template>


  <xsl:template name="build-catalog">
    <xsl:variable name="description" as="node()">
      <xsl:choose>
        <xsl:when test="catalogueDescriptionRecord/*">
          <xsl:apply-templates select="catalogueDescriptionRecord/*"
                               mode="build-catalogue-description"/>
        </xsl:when>
        <xsl:otherwise>
          <catalogue>
            <uuid><xsl:value-of select="$env/system/site/siteId"/></uuid>
            <title xml:lang="{$iso2letterLanguageCode}">
              <xsl:value-of select="$env/system/site/name"/>
            </title>
            <description xml:lang="{$iso2letterLanguageCode}">
              <xsl:value-of
                select="concat($env/system/site/name, ' (', $env/system/site/organization, ')')"/>
            </description>
            <publisher xml:lang="{$iso2letterLanguageCode}"
                       mail="{$env/system/site/organizationMail}"
                       url="{$env/system/site/organizationUrl}">
              <xsl:value-of select="$env/system/site/organization"/>
            </publisher>
            <url>
              <xsl:value-of select="$env/system/site/url"/>
            </url>
          </catalogue>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <dcat:Catalog rdf:about="{$resourcePrefix}catalogs/{$env/system/site/siteId}">
      <!-- A name given to the catalog. -->
      <!-- TODO
      No idea why the xml:lang attribute is not in the output
      and is replaced by the element name.
          <dct:title xmlns:dct="http://purl.org/dc/terms/" dct:title="nl">name</dct:title>
      -->
      <xsl:for-each select="$description/title">
        <dct:title xml:lang="{@xml:lang}"><xsl:value-of select="."/></dct:title>
      </xsl:for-each>

      <!-- free-text account of the catalog. -->
      <xsl:for-each select="$description/description">
        <dct:description xml:lang="{@xml:lang}"><xsl:value-of select="."/></dct:description>
      </xsl:for-each>

      <!-- Unique identifier of the catalog -->
      <dct:identifier>
        <xsl:value-of select="$description/uuid"/>
      </dct:identifier>

      <!-- The entity responsible for making the catalog online. -->
      <xsl:for-each select="$description/publisher">
        <dct:publisher>
          <!-- Organization in charge of the catalogue defined in the administration > system configuration -->
          <foaf:Agent
            rdf:about="{$resourcePrefix}/organizations/{encode-for-uri(normalize-space(.))}">
            <foaf:name xml:lang="{@xml:lang}">
              <xsl:value-of select="."/>
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
      </xsl:for-each>

      <!-- The homepage of the catalog -->
      <foaf:homepage>
        <foaf:Document>
          <xsl:if test="normalize-space($description/url) != ''">
            <xsl:attribute name="rdf:about" select="$description/url"/>
          </xsl:if>
          <xsl:for-each select="$description/title">
            <foaf:name xml:lang="{@xml:lang}"><xsl:value-of select="."/></foaf:name>
          </xsl:for-each>
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
          <xsl:for-each select="$description/publisher">
            <vcard:organization-name>
              <xsl:value-of select="."/>
            </vcard:organization-name>
            <xsl:if test="normalize-space(@mail) != ''">
              <vcard:hasEmail
                rdf:resource="mailto:{normalize-space(@mail)}"/>
            </xsl:if>
            <xsl:if test="normalize-space(@url) != ''">
              <vcard:hasURL rdf:resource="{normalize-space(@url)}"/>
            </xsl:if>
          </xsl:for-each>
        </vcard:Organization>
      </dcat:contactPoint>


      <xsl:apply-templates mode="dcat-record-reference"
                           select="records/*"/>
    </dcat:Catalog>
  </xsl:template>

  <xsl:template mode="dcat" match="*"/>
  <xsl:template mode="dcat-record-reference" match="*"/>

</xsl:stylesheet>
