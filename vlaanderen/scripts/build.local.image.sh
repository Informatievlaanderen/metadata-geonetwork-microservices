#!/bin/bash
# figure out the right versions
main_version=$(mvn -f ../../pom.xml help:evaluate -Dexpression=project.version -q -DforceStdout)
vl_version=$(mvn -f ../pom.xml help:evaluate -Dexpression=project.version -q -DforceStdout)
echo "main version: $main_version"
echo "vl version: $vl_version"

# build a new docker image
(
  cd ../..
  mvn clean install -Drelax -P-docker
)

# retag the images with vl version
oldtag="gn-cloud-ogc-api-records-service:$main_version"
newtag="localhost/gn-cloud-ogc-api-records-service:vl-$vl_version"
docker tag "$oldtag" "$newtag"
