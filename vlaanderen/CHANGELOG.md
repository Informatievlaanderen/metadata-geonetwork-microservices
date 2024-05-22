# Changelog

All notable changes to this project will be documented in this file. These changes are specific to Vlaanderen, important
[geonetwork-microservices](https://github.com/geonetwork/geonetwork-microservices) changes are linked or embedded.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/), and this project adheres
to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.3-SNAPSHOT]
- Merge upstream changes, includes upgrade to Elasticsearch 8 - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/35325)
- Fix for geonetwork-proxied /api/openapi redirect - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/35866)

## [1.1.2] - 2024-04-30
- Fix missing native DCAT DataService from RDF output - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/32778)
- Return HTTP error when no record found for RDF export, instead of an empty catalog - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/32778)
- Move most of the XML namespaces alias at the top of the RDF output document - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/32778)
- Always add default sorting on UUID - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/32778)
- Prettify XML output
- Fix metadatacenter reference in RDF output - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/34567)

## [1.1.1] - 2023-11-22
- Fix unmapped `mdcat:status` due to http/https inconsistency in thesaurus and metadata - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/29881)
- Implement datasets <> services relation mapping - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/29881)
- Fix batch export to dcat_ap_vl format - [pr](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/29881)

## [1.1.0] - 2023-09-26
- Merged upstream main branch (4.2.5-1) [PR](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/27231)

## [1.0.4]
- Bumped geonetwork core dependencies to 4.2.5 (breaking change in Language table) [PR](https://agiv.visualstudio.com/Metadata/_git/MetadataGeonetworkMicroservices/pullrequest/26653)

## [1.0.1] - 2023-06-16
- Added DCAT-AP-NL support to ogc-api-records-service

## [1.0.0] - 2023-06-15
- [core] based on 4.2.5-SNAPSHOT, May 10
- Introduced semver versioning for Flemish modifications