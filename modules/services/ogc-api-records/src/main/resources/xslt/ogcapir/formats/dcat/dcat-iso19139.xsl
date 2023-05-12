<?xml version="1.0" encoding="UTF-8"?>
<!--
  Copyright 2015-2020 EUROPEAN UNION
  Licensed under the EUPL, Version 1.2 or - as soon they will be approved by
  the European Commission - subsequent versions of the EUPL (the "Licence");
  You may not use this work except in compliance with the Licence.
  You may obtain a copy of the Licence at:

  https://joinup.ec.europa.eu/collection/eupl

  Unless required by applicable law or agreed to in writing, software
  distributed under the Licence is distributed on an "AS IS" basis,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the Licence for the specific language governing permissions and
  limitations under the Licence.

  Contributors: ISA GeoDCAT-AP Working Group <https://github.com/SEMICeu/geodcat-ap>

  This work was originally supported by the EU Interoperability Solutions for
  European Public Administrations Programme (http://ec.europa.eu/isa)
  through Action 1.17: Re-usable INSPIRE Reference Platform
  (http://ec.europa.eu/isa/actions/01-trusted-information-exchange/1-17action_en.htm).

-->
<xsl:stylesheet xmlns:adms="http://www.w3.org/ns/adms#"
                xmlns:cnt="http://www.w3.org/2011/content#"
                xmlns:dcat="http://www.w3.org/ns/dcat#"
                xmlns:dct="http://purl.org/dc/terms/"
                xmlns:earl="http://www.w3.org/ns/earl#"
                xmlns:foaf="http://xmlns.com/foaf/0.1/"
                xmlns:gco="http://www.isotc211.org/2005/gco"
                xmlns:gmd="http://www.isotc211.org/2005/gmd"
                xmlns:gml="http://www.opengis.net/gml"
                xmlns:gmx="http://www.isotc211.org/2005/gmx"
                xmlns:i="http://inspire.ec.europa.eu/schemas/common/1.0"
                xmlns:locn="http://www.w3.org/ns/locn#"
                xmlns:owl="http://www.w3.org/2002/07/owl#"
                xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
                xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
                xmlns:schema="http://schema.org/"
                xmlns:skos="http://www.w3.org/2004/02/skos/core#"
                xmlns:srv="http://www.isotc211.org/2005/srv"
                xmlns:vcard="http://www.w3.org/2006/vcard/ns#"
                xmlns:wdrs="http://www.w3.org/2007/05/powder-s#"
                xmlns:xlink="http://www.w3.org/1999/xlink"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:dqv="http://www.w3.org/ns/dqv#"
                xmlns:geodcat="http://data.europa.eu/930/"
                xmlns:sdmx-attribute="http://purl.org/linked-data/sdmx/2009/attribute#"
                xmlns:atom="http://www.w3.org/2005/Atom"
                xmlns:georss="http://www.georss.org/georss"
                xmlns:xs="http://www.w3.org/2001/XMLSchema#"
                exclude-result-prefixes="earl gco gmd gml gmx i srv xlink xsi xsl wdrs"
                version="2.0">

  <xsl:output method="xml"
              indent="yes"
              encoding="utf-8"
              cdata-section-elements="" />

  <!--
    Mapping parameters
    ==================
      This section includes mapping parameters by the XSLT processor used, or, possibly, manually.
  -->
  <xsl:param name="OgcAPIUrl" select="'http://localhost:8080'" />
  <xsl:param name="isSubset" select="'no'" />

  <!--
    Global variables
    =======================
  -->

  <!--
    This variable specifies whether the coupled resource, referenced via @xlink:href, should be looked up to fetch the resource's  unique resource identifier (i.e., code and code space). More precisely:
    - value "enabled": The coupled resource is looked up
    - value "disabled": The coupled resource is not looked up
    CAVEAT: Using this feature may cause the transformation to hang, in case the URL in @xlink:href is broken, the request hangs indefinitely, or does not return the expected resource (e.g., and HTML page, instead of an XML-encoded ISO 19139 record). It is strongly recommended that this issue is dealt with by using appropriate configuration parameters and error handling (e.g., by specifying a timeout on HTTP calls and by setting the HTTP Accept header to "application/xml").
  -->
  <xsl:variable name="CoupledResourceLookUp" select="'disabled'" />

  <!-- Variables to be used to convert strings into lower/uppercase by using the translate() function. -->
  <xsl:variable name="lowercase" select="'abcdefghijklmnopqrstuvwxyz'"/>
  <xsl:variable name="uppercase" select="'ABCDEFGHIJKLMNOPQRSTUVWXYZ'"/>

  <!-- URIs, URNs and names for spatial reference system registers. -->
  <xsl:variable name="EpsgSrsBaseUri" select="'http://www.opengis.net/def/crs/EPSG/0'"/>
  <xsl:variable name="EpsgSrsBaseUrn" select="'urn:ogc:def:crs:EPSG'"/>
  <xsl:variable name="EpsgSrsName" select="'EPSG Coordinate Reference Systems'"/>
  <xsl:variable name="OgcSrsBaseUri" select="'http://www.opengis.net/def/crs/OGC'"/>
  <xsl:variable name="OgcSrsBaseUrn" select="'urn:ogc:def:crs:OGC'"/>
  <xsl:variable name="OgcSrsName" select="'OGC Coordinate Reference Systems'"/>

  <!-- URI and URN for CRS84. -->
  <xsl:variable name="Crs84Uri" select="concat($OgcSrsBaseUri,'/1.3/CRS84')"/>
  <xsl:variable name="Crs84Urn" select="concat($OgcSrsBaseUrn,':1.3:CRS84')"/>

  <!-- URI and URN for ETRS89. -->
  <xsl:variable name="Etrs89Uri" select="concat($EpsgSrsBaseUri,'/4258')"/>
  <xsl:variable name="Etrs89Urn" select="concat($EpsgSrsBaseUrn,'::4258')"/>

  <!-- URI and URN of the spatial reference system (SRS) used in the bounding box.
       The default SRS is CRS84. If a different SRS is used, also parameter
       $SrsAxisOrder must be specified. -->

  <!-- The SRS URI is used in the WKT and GML encodings of the bounding box. -->
  <xsl:variable name="SrsUri" select="$Crs84Uri"/>
  <!-- The SRS URN is used in the GeoJSON encoding of the bounding box. -->
  <xsl:variable name="SrsUrn" select="$Crs84Urn"/>

  <!-- Axis order for the reference SRS:
       - "LonLat": longitude / latitude
       - "LatLon": latitude / longitude.
       The axis order must be specified only if the reference SRS is different from CRS84.
       If the reference SRS is CRS84, this parameter is ignored. -->
  <xsl:variable name="SrsAxisOrder" select="'LonLat'"/>

  <!-- Namespaces -->
  <xsl:variable name="xsd" select="'http://www.w3.org/2001/XMLSchema#'"/>
  <xsl:variable name="dct" select="'http://purl.org/dc/terms/'"/>
  <xsl:variable name="dctype" select="'http://purl.org/dc/dcmitype/'"/>
  <xsl:variable name="dcat" select="'http://www.w3.org/ns/dcat#'"/>
  <xsl:variable name="gsp" select="'http://www.opengis.net/ont/geosparql#'"/>
  <xsl:variable name="foaf" select="'http://xmlns.com/foaf/0.1/'"/>
  <xsl:variable name="vcard" select="'http://www.w3.org/2006/vcard/ns#'"/>
  <xsl:variable name="skos" select="'http://www.w3.org/2004/02/skos/core#'"/>
  <xsl:variable name="op" select="'http://publications.europa.eu/resource/authority/'"/>
  <xsl:variable name="opcountry" select="concat($op,'country/')"/>
  <xsl:variable name="oplang" select="concat($op,'language/')"/>
  <xsl:variable name="opcb" select="concat($op,'corporate-body/')"/>
  <xsl:variable name="opfq" select="concat($op,'frequency/')"/>
  <xsl:variable name="cldFrequency" select="'http://purl.org/cld/freq/'"/>

  <!-- This is used as the datatype for the GeoJSON-based encoding of the bounding box. -->
  <xsl:variable name="geojsonMediaTypeUri" select="'https://www.iana.org/assignments/media-types/application/vnd.geo+json'" />
  <xsl:variable name="geojsonLiteralMediaTypeUri" select="'http://www.opengis.net/ont/geosparql#geoJSONLiteral'" />

  <!-- INSPIRE code list URIs -->
  <xsl:variable name="INSPIRECodelistUri" select="'http://inspire.ec.europa.eu/metadata-codelist/'"/>
  <xsl:variable name="SpatialDataServiceCategoryCodelistUri" select="concat($INSPIRECodelistUri,'SpatialDataServiceCategory')"/>
  <xsl:variable name="DegreeOfConformityCodelistUri" select="concat($INSPIRECodelistUri,'DegreeOfConformity')"/>
  <xsl:variable name="ResourceTypeCodelistUri" select="concat($INSPIRECodelistUri,'ResourceType')"/>
  <xsl:variable name="ResponsiblePartyRoleCodelistUri" select="concat($INSPIRECodelistUri,'ResponsiblePartyRole')"/>
  <xsl:variable name="SpatialDataServiceTypeCodelistUri" select="concat($INSPIRECodelistUri,'SpatialDataServiceType')"/>
  <xsl:variable name="TopicCategoryCodelistUri" select="concat($INSPIRECodelistUri,'TopicCategory')"/>

  <!-- INSPIRE code list URIs (not yet supported; the URI pattern is tentative) -->
  <xsl:variable name="SpatialRepresentationTypeCodelistUri" select="concat($INSPIRECodelistUri,'SpatialRepresentationType')"/>
  <xsl:variable name="MaintenanceFrequencyCodelistUri" select="concat($INSPIRECodelistUri,'MaintenanceFrequencyCode')"/>

  <!-- INSPIRE glossary URI -->
  <xsl:variable name="INSPIREGlossaryUri" select="'http://inspire.ec.europa.eu/glossary/'"/>

  <!-- Other variables -->
  <xsl:variable name="allThesauri">
<!--     <xsl:copy-of select="document('./thesauri/language.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/TopicCategory.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/frequency.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/access-rights.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/SpatialRepresentationType.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/ServiceType.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/federalthesaurus.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/inspire-theme.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/SpatialScope.rdf')"/> -->
<!--     <xsl:copy-of select="document('./thesauri/LimitationsOnPublicAccess.rdf')"/> -->
<!--     <xsl:if test="//gmd:hierarchyLevel/gmd:MD_ScopeCode[@codeListValue = ('dataset', 'series')]"> -->
<!--       <xsl:copy-of select="document('./thesauri/file-types.rdf')"/> -->
<!--     </xsl:if> -->
  </xsl:variable>


  <!--
    Master template
    ===============
   -->
  <xsl:template match="/">
    <rdf:RDF>
      <dcat:Catalog>
        <xsl:variable name="records">
          <xsl:apply-templates select="gmd:MD_Metadata|//gmd:MD_Metadata"/>
        </xsl:variable>
        <xsl:choose>
          <xsl:when test="$isSubset = 'yes'">
            <dct:title xml:lang="en">A subset of the Geoportal of the Belgian federal institutions</dct:title>
            <dct:title xml:lang="fr">Un sous-ensemble du Géoportail des institutions fédérales belges</dct:title>
            <dct:title xml:lang="nl">Een deelverzameling van Geoportaal van de Belgische federale instellingen</dct:title>
            <dct:title xml:lang="de">Eine Teilmenge der Geoportal des belgischen Institutionen</dct:title>
          </xsl:when>
          <xsl:otherwise>
            <dct:title xml:lang="en">Geoportal of the Belgian federal institutions</dct:title>
            <dct:title xml:lang="fr">Géoportail des institutions fédérales belges</dct:title>
            <dct:title xml:lang="nl">Geoportaal van de Belgische federale instellingen</dct:title>
            <dct:title xml:lang="de">Geoportal des belgischen Institutionen</dct:title>
          </xsl:otherwise>
        </xsl:choose>
        <dct:description xml:lang="en">The catalogue contains the metadata records for the geographical data and services of the Belgian federal institutions.</dct:description>
        <dct:description xml:lang="fr">Le catalogue contient les fiches de métadonnées des données et services géographiques des institutions fédérales belges.</dct:description>
        <dct:description xml:lang="nl">De catalogus bevat de metadatafiches voor de geografische gegevens en services van de Belgische federale instellingen.</dct:description>
        <dct:description xml:lang="de">Der Katalog enthält die Metadatenblätter für die geografischen Daten und Dienste der belgischen föderalen Institutionen.</dct:description>
        <dct:identifier>be.geo.data.catalog</dct:identifier>
        <dct:publisher>
          <foaf:Organization rdf:about="https://org.belgif.be/id/CbeRegisteredEntity/216755012">
            <foaf:name xml:lang="en">National Geographic Institute</foaf:name>
            <foaf:name xml:lang="fr">Institut géographique national</foaf:name>
            <foaf:name xml:lang="nl">Nationaal Geografisch Instituut</foaf:name>
            <foaf:name xml:lang="de">Nationales geographisches Institut</foaf:name>
            <foaf:mbox rdf:resource="mailto:products@ngi.be"/>
            <foaf:workplaceHomepage>
              <rdf:Description rdf:about="https://www.ngi.be/website">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/NLD"/>
              </rdf:Description>
              <rdf:Description rdf:about="https://www.ngi.be/website/fr">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/FRA"/>
              </rdf:Description>
            </foaf:workplaceHomepage>
            <locn:address>
              <locn:Address rdf:about="https://databrussels.be/id/address/187993">
                <locn:thoroughfare xml:lang="en">Kortenberglaan 115</locn:thoroughfare>
                <locn:thoroughfare xml:lang="fr">Avenue de Cortenbergh 115</locn:thoroughfare>
                <locn:thoroughfare xml:lang="nl">Kortenberglaan 115</locn:thoroughfare>
                <locn:thoroughfare xml:lang="de">Avenue de Cortenbergh 115</locn:thoroughfare>
                <locn:postName xml:lang="en">Brussels</locn:postName>
                <locn:postName xml:lang="fr">Bruxelles</locn:postName>
                <locn:postName xml:lang="nl">Brussel</locn:postName>
                <locn:postName xml:lang="de">Brüssel</locn:postName>
                <locn:postCode>1000</locn:postCode>
                <locn:adminUnitL1 xml:lang="en">Belgium</locn:adminUnitL1>
                <locn:adminUnitL1 xml:lang="fr">Belgique</locn:adminUnitL1>
                <locn:adminUnitL1 xml:lang="nl">België</locn:adminUnitL1>
                <locn:adminUnitL1 xml:lang="de">Belgien</locn:adminUnitL1>
              </locn:Address>
            </locn:address>
          </foaf:Organization>
        </dct:publisher>
        <foaf:homepage>
          <rdf:Description rdf:about="https://www.geo.be/home?l=en">
            <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/ENG"/>
          </rdf:Description>
          <rdf:Description rdf:about="https://www.geo.be/home?l=de">
            <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/DEU"/>
          </rdf:Description>
          <rdf:Description rdf:about="https://www.geo.be/home?l=fr">
            <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/FRA"/>
          </rdf:Description>
          <rdf:Description rdf:about="https://www.geo.be/home?l=nl">
            <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/NLD"/>
          </rdf:Description>
        </foaf:homepage>
        <dct:language>
          <skos:Concept rdf:about="http://publications.europa.eu/resource/authority/language/ENG">
            <skos:prefLabel xml:lang="de">Englisch</skos:prefLabel>
            <skos:prefLabel xml:lang="en">English</skos:prefLabel>
            <skos:prefLabel xml:lang="fr">anglais</skos:prefLabel>
            <skos:prefLabel xml:lang="nl">Engels</skos:prefLabel>
            <skos:inScheme rdf:resource="http://publications.europa.eu/resource/authority/language"/>
          </skos:Concept>
        </dct:language>
        <dct:language>
          <skos:Concept rdf:about="http://publications.europa.eu/resource/authority/language/DEU">
            <skos:prefLabel xml:lang="de">Deutsch</skos:prefLabel>
            <skos:prefLabel xml:lang="en">German</skos:prefLabel>
            <skos:prefLabel xml:lang="fr">allemand</skos:prefLabel>
            <skos:prefLabel xml:lang="nl">Duits</skos:prefLabel>
            <skos:inScheme rdf:resource="http://publications.europa.eu/resource/authority/language"/>
          </skos:Concept>
        </dct:language>
        <dct:language>
          <skos:Concept rdf:about="http://publications.europa.eu/resource/authority/language/FRA">
            <skos:prefLabel xml:lang="de">Französisch</skos:prefLabel>
            <skos:prefLabel xml:lang="en">French</skos:prefLabel>
            <skos:prefLabel xml:lang="fr">français</skos:prefLabel>
            <skos:prefLabel xml:lang="nl">Frans</skos:prefLabel>
            <skos:inScheme rdf:resource="http://publications.europa.eu/resource/authority/language"/>
          </skos:Concept>
        </dct:language>
        <dct:language>
          <skos:Concept rdf:about="http://publications.europa.eu/resource/authority/language/NLD">
            <skos:prefLabel xml:lang="de">Niederländisch</skos:prefLabel>
            <skos:prefLabel xml:lang="en">Dutch</skos:prefLabel>
            <skos:prefLabel xml:lang="fr">néerlandais</skos:prefLabel>
            <skos:prefLabel xml:lang="nl">Nederlands</skos:prefLabel>
            <skos:inScheme rdf:resource="http://publications.europa.eu/resource/authority/language"/>
          </skos:Concept>
        </dct:language>
        <!-- TODO dct:issued -->
        <xsl:variable name="boundingBox">
          <gmd:EX_GeographicBoundingBox>
            <gmd:westBoundLongitude>
              <gco:Decimal>
                <xsl:value-of select="min(//gmd:MD_Metadata//gmd:EX_GeographicBoundingBox/gmd:westBoundLongitude/gco:Decimal)"/>
              </gco:Decimal>
            </gmd:westBoundLongitude>
            <gmd:eastBoundLongitude>
              <gco:Decimal>
                <xsl:value-of select="max(//gmd:MD_Metadata//gmd:EX_GeographicBoundingBox/gmd:eastBoundLongitude/gco:Decimal)"/>
              </gco:Decimal>
            </gmd:eastBoundLongitude>
            <gmd:southBoundLatitude>
              <gco:Decimal>
                <xsl:value-of select="min(//gmd:MD_Metadata//gmd:EX_GeographicBoundingBox/gmd:southBoundLatitude/gco:Decimal)"/>
              </gco:Decimal>
            </gmd:southBoundLatitude>
            <gmd:northBoundLatitude>
              <gco:Decimal>
                <xsl:value-of select="max(//gmd:MD_Metadata//gmd:EX_GeographicBoundingBox/gmd:northBoundLatitude/gco:Decimal)"/>
              </gco:Decimal>
            </gmd:northBoundLatitude>
          </gmd:EX_GeographicBoundingBox>
        </xsl:variable>
        <xsl:apply-templates select="$boundingBox/*">
          <xsl:with-param name="MetadataLanguage" select="'en'"/>
        </xsl:apply-templates>
        <dcat:contactPoint>
          <vcard:Organization rdf:about="https://org.belgif.be/id/CbeRegisteredEntity/216755012">
            <vcard:organization-name xml:lang="en">National Geographic Institute</vcard:organization-name>
            <vcard:organization-name xml:lang="fr">Institut géographique national</vcard:organization-name>
            <vcard:organization-name xml:lang="nl">Nationaal Geografisch Instituut</vcard:organization-name>
            <vcard:organization-name xml:lang="de">Nationales geographisches Institut</vcard:organization-name>
            <vcard:hasEmail rdf:resource="mailto:products@ngi.be"/>
            <vcard:hasURL>
              <rdf:Description rdf:about="https://www.ngi.be/website">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/NLD"/>
              </rdf:Description>
              <rdf:Description rdf:about="https://www.ngi.be/website/fr">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/FRA"/>
              </rdf:Description>
            </vcard:hasURL>
            <vcard:hasAddress>
              <vcard:Address rdf:about="https://databrussels.be/id/address/187993">
                <vcard:street-address xml:lang="en">Kortenberglaan 115</vcard:street-address>
                <vcard:street-address xml:lang="fr">Avenue de Cortenbergh 115</vcard:street-address>
                <vcard:street-address xml:lang="nl">Kortenberglaan 115</vcard:street-address>
                <vcard:street-address xml:lang="de">Avenue de Cortenbergh 115</vcard:street-address>
                <vcard:locality xml:lang="en">Brussels</vcard:locality>
                <vcard:locality xml:lang="fr">Bruxelles</vcard:locality>
                <vcard:locality xml:lang="nl">Brussel</vcard:locality>
                <vcard:locality xml:lang="de">Brüssel</vcard:locality>
                <vcard:postal-code>1000</vcard:postal-code>
                <vcard:country-name xml:lang="en">Belgium</vcard:country-name>
                <vcard:country-name xml:lang="fr">Belgique</vcard:country-name>
                <vcard:country-name xml:lang="nl">België</vcard:country-name>
                <vcard:country-name xml:lang="de">Belgien</vcard:country-name>
              </vcard:Address>
            </vcard:hasAddress>
          </vcard:Organization>
        </dcat:contactPoint>
        <dct:isPartOf>
          <dcat:Catalog>
            <dct:title xml:lang="nl">Catalogue Open data national</dct:title>
            <dct:title xml:lang="fr">Nationale Open data catalogus</dct:title>
            <dct:identifier>http://data.gov.be/id/catalog</dct:identifier>
            <dct:publisher>
              <foaf:Organization rdf:about="https://org.belgif.be/id/CbeRegisteredEntity/0671516647">
                <foaf:name xml:lang="nl">FOD Beleid &amp; Ondersteuning</foaf:name>
                <foaf:name xml:lang="fr">SPF Stratégie &amp; Appui</foaf:name>
                <dct:type rdf:resource="http://purl.org/adms/publishertype/NationalAuthority/"/>
                <foaf:mbox rdf:resource="mailto:opendata@belgium.be"/>
                <foaf:workplaceHomepage>
                  <rdf:Description rdf:about="https://bosa.belgium.be/nl">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/NLD"/>
                  </rdf:Description>
                </foaf:workplaceHomepage>
                <foaf:workplaceHomepage>
                  <rdf:Description rdf:about="https://bosa.belgium.be/fr">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/FRA"/>
                  </rdf:Description>
                </foaf:workplaceHomepage>
                <foaf:workplaceHomepage>
                  <rdf:Description rdf:about="https://bosa.belgium.be/en">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/ENG"/>
                  </rdf:Description>
                </foaf:workplaceHomepage>
                <foaf:workplaceHomepage>
                  <rdf:Description rdf:about="https://bosa.belgium.be/de">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/DEU"/>
                  </rdf:Description>
                </foaf:workplaceHomepage>
                <locn:address>
                  <locn:Address rdf:about="https://databrussels.be/id/address/210591">
                    <locn:thoroughfare xml:lang="nl">Simon Bolivarlaan 30</locn:thoroughfare>
                    <locn:thoroughfare xml:lang="fr">Boulevard Simon Bolivar, 30</locn:thoroughfare>
                    <locn:postName xml:lang="nl">Brussel</locn:postName>
                    <locn:postName xml:lang="fr">Bruxelles</locn:postName>
                    <locn:postCode>1000</locn:postCode>
                    <locn:adminUnitL1 xml:lang="nl">België</locn:adminUnitL1>
                    <locn:adminUnitL1 xml:lang="fr">Belgique</locn:adminUnitL1>
                  </locn:Address>
                </locn:address>
              </foaf:Organization>
            </dct:publisher>
            <foaf:homepage>
              <rdf:Description rdf:about="https://data.gov.be/nl">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/NLD"/>
              </rdf:Description>
            </foaf:homepage>
            <foaf:homepage>
              <rdf:Description rdf:about="https://data.gov.be/fr">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/FRA"/>
              </rdf:Description>
            </foaf:homepage>
            <foaf:homepage>
              <rdf:Description rdf:about="https://data.gov.be/nl">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/ENG"/>
              </rdf:Description>
            </foaf:homepage>
            <foaf:homepage>
              <rdf:Description rdf:about="https://data.gov.be/de">
                <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/DEU"/>
              </rdf:Description>
            </foaf:homepage>
            <dct:language>
              <skos:Concept rdf:about="http://publications.europa.eu/resource/authority/language/NLD">
                <skos:prefLabel xml:lang="nl">Nederlands</skos:prefLabel>
                <skos:prefLabel xml:lang="fr">Néerlandais</skos:prefLabel>
                <rdf:type rdf:resource="dct:LinguisticSystem"/>
              </skos:Concept>
            </dct:language>
            <dct:language>
              <skos:Concept rdf:about="http://publications.europa.eu/resource/authority/language/FRA">
                <skos:prefLabel xml:lang="nl">Frans</skos:prefLabel>
                <skos:prefLabel xml:lang="fr">Français</skos:prefLabel>
                <rdf:type rdf:resource="dct:LinguisticSystem"/>
              </skos:Concept>
            </dct:language>
            <dct:spatial>
              <dct:Location>
                <locn:geometry rdf:datatype="http://www.opengis.net/ont/geosparql#:wktLiteral">POLYGON((2.54 51.51,6.41 51.51,6.41 49.49,2.54 49.49,2.54 51.51))</locn:geometry>
                <locn:geometry rdf:datatype="http://www.opengis.net/ont/geosparql#:gmlLiteral">&lt;gml:Envelope srsName="http://www.opengis.net/def/crs/OGC/1.3/CRS84"&gt;&lt;gml:lowerCorner&gt;2.54 49.49&lt;/gml:lowerCorner&gt;&lt;gml:upperCorner&gt;6.41 51.51&lt;/gml:upperCorner&gt;&lt;/gml:Envelope&gt;</locn:geometry>
                <locn:geometry rdf:datatype="https://www.iana.org/assignments/media-types/application/vnd.geo+json">{"type":"Polygon","coordinates":[[[2.54,51.51],[6.41,51.51],[6.41,49.49],[2.54,49.49],[2.54,51.51]]]}</locn:geometry>
                <locn:geometry rdf:datatype="http://www.opengis.net/ont/geosparql#:geoJSONLiteral">{"type":"Polygon","coordinates":[[[2.54,51.51],[6.41,51.51],[6.41,49.49],[2.54,49.49],[2.54,51.51]]]}</locn:geometry>
                <dcat:bbox rdf:datatype="http://www.opengis.net/ont/geosparql#:wktLiteral">POLYGON((2.54 51.51,6.41 51.51,6.41 49.49,2.54 49.49,2.54 51.51))</dcat:bbox>
                <dcat:bbox rdf:datatype="http://www.opengis.net/ont/geosparql#:gmlLiteral">&lt;gml:Envelope srsName="http://www.opengis.net/def/crs/OGC/1.3/CRS84"&gt;&lt;gml:lowerCorner&gt;2.54 49.49&lt;/gml:lowerCorner&gt;&lt;gml:upperCorner&gt;6.41 51.51&lt;/gml:upperCorner&gt;&lt;/gml:Envelope&gt;</dcat:bbox>
                <dcat:bbox rdf:datatype="https://www.iana.org/assignments/media-types/application/vnd.geo+json">{"type":"Polygon","coordinates":[[[2.54,51.51],[6.41,51.51],[6.41,49.49],[2.54,49.49],[2.54,51.51]]]}</dcat:bbox>
                <dcat:bbox rdf:datatype="http://www.opengis.net/ont/geosparql#:geoJSONLiteral">{"type":"Polygon","coordinates":[[[2.54,51.51],[6.41,51.51],[6.41,49.49],[2.54,49.49],[2.54,51.51]]]}</dcat:bbox>
              </dct:Location>
            </dct:spatial>
            <dcat:contactPoint>
              <vcard:Organization rdf:about="https://org.belgif.be/id/CbeRegisteredEntity/0671516647">
                <vcard:organization-name xml:lang="nl">FOD Beleid &amp; Ondersteuning</vcard:organization-name>
                <vcard:organization-name xml:lang="fr">SPF Stratégie &amp; Appui</vcard:organization-name>
                <vcard:hasEmail rdf:resource="mailto:opendata@belgium.be"/>
                <vcard:hasURL>
                  <rdf:Description rdf:about="https://bosa.belgium.be/nl">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/NLD"/>
                  </rdf:Description>
                </vcard:hasURL>
                <vcard:hasURL>
                  <rdf:Description rdf:about="https://bosa.belgium.be/fr">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/FRA"/>
                  </rdf:Description>
                </vcard:hasURL>
                <vcard:hasURL>
                  <rdf:Description rdf:about="https://bosa.belgium.be/en">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/ENG"/>
                  </rdf:Description>
                </vcard:hasURL>
                <vcard:hasURL>
                  <rdf:Description rdf:about="https://bosa.belgium.be/de">
                    <dct:language rdf:resource="http://publications.europa.eu/resource/authority/language/DEU"/>
                  </rdf:Description>
                </vcard:hasURL>
                <vcard:hasAddress>
                  <vcard:Address rdf:about="https://databrussels.be/id/address/210591">
                    <vcard:street-address xml:lang="nl">Simon Bolivarlaan 30</vcard:street-address>
                    <vcard:street-address xml:lang="fr">Boulevard Simon Bolivar, 30</vcard:street-address>
                    <vcard:locality xml:lang="nl">Brussel</vcard:locality>
                    <vcard:locality xml:lang="fr">Bruxelles</vcard:locality>
                    <vcard:postal-code>1000</vcard:postal-code>
                    <vcard:country-name xml:lang="nl">België</vcard:country-name>
                    <vcard:country-name xml:lang="fr">Belgique</vcard:country-name>
                  </vcard:Address>
                </vcard:hasAddress>
              </vcard:Organization>
            </dcat:contactPoint>
          </dcat:Catalog>
        </dct:isPartOf>
      </dcat:Catalog>
    </rdf:RDF>
  </xsl:template>
</xsl:stylesheet>
