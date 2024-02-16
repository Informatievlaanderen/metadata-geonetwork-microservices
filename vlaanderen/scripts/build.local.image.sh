#!/bin/bash
# check that we're on java 11, otherwise the build / docker image fails
java_version=$(javac -version)
regex="^javac 11\..*$"
if [[ "$java_version" =~ $regex ]]
then
  echo "Using Java 11, proceeding...."
else
  echo "Not using Java 11 (currently on $java_version), breaking off."
  exit 1
fi

# figure out the right versions
main_version=$(mvn -f ../../pom.xml help:evaluate -Dexpression=project.version -q -DforceStdout)
vl_version=$(mvn -f ../pom.xml help:evaluate -Dexpression=project.version -q -DforceStdout)
echo "main version: $main_version"
echo "vl version: $vl_version"

# build a new docker image
(
  cd ../..
  mvn clean install -Drelax -Pdocker
)

# retag the images with vl version
oldtag="gn-cloud-ogc-api-records-service:$main_version"
newtag="localhost/gn-cloud-ogc-api-records-service:vl-$vl_version"
docker tag "$oldtag" "$newtag"
