#!/bin/bash

if [ -z "$1" ]
  then
    echo "No argument supplied Please provide valid argument"
    echo "Example ./build.sh <version number>"
    exit 1
fi

VERSION=$1
CONTAINER_NAME="Hmscommon-build-temp"
DIR=$(dirname "$PWD") 
echo ${DIR}
echo "===================================================="
echo "============ Build hmscommon ===================="
echo "===================================================="

if [ -f /.dockerenv ]; then
    echo "----------------------------- Javafx install -----------------------------------------"
    apk --no-cache add ca-certificates wget
	wget --quiet --output-document=/etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub
	wget https://github.com/sgerrand/alpine-pkg-java-openjfx/releases/download/8.151.12-r0/java-openjfx-8.151.12-r0.apk
	apk add --no-cache java-openjfx-8.151.12-r0.apk
    echo "------------------------- script invoked in docker (Jenkins Build) --------------------"
   # mvn install -f hmsdependency/pom.xml -Dmaven.test.skip=true 
    mvn install -Dmaven.test.skip=true 
    mvn install docker:build -Dbuild.number="hmscommon-$VERSION" -f hmscommon/pom.xml
    echo "---------------------------------------------------------------------------------------"
else
    echo "------------------------- script not invoked in docker(Local Build) --------------------"
    docker rm -f $CONTAINER_NAME
    echo "sudo docker run -it -u=root:root -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v ${HOME}/.m2/:/var/maven/.m2 -e MAVEN_CONFIG=/var/maven/.m2 --add-host "maven.netgear.com:172.29.27.150" --name $CONTAINER_NAME -v ${DIR}:${DIR} -w ${DIR} maven:3.5.4-jdk-8 hmscommon/build.sh $VERSION"
    echo "--------------------------------------------------------"
    docker run -it -u=root:root -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker -v $HOME/.m2/:/var/maven/.m2 -v ${DIR}:${DIR} -w ${DIR} -e MAVEN_CONFIG=/var/maven/.m2 --add-host "maven.netgear.com:172.29.27.150" --name $CONTAINER_NAME  maven:3.5.4-jdk-8 hmscommon/build.sh $VERSION
    echo "---------------------------------------------------------------------------------------"
fi
