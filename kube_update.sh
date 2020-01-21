#!/bin/bash

if readlink /proc/$$/exe | grep -q "dash"; then
        echo "This script needs to be run with bash, not sh"
        exit
fi

if [[ "$EUID" -ne 0 ]]; then
        echo "Sorry, you need to run this as root"
        exit
fi


function yellow { echo -e "\e[33m$@\e[0m" ; }
function red { echo -e "\e[31m$@\e[0m" ; }

update_dockerfile () {
   echo "FROM openjdk:8-jre" > Dockerfile
   echo "LABEL maintainer=\"Midhlaj VS <midhlaj.vs@nexquare.io>\"" >> Dockerfile
   echo "LABEL site=\"https://nexquare.io/\"" >> Dockerfile
   echo " " >> Dockerfile
   echo "ARG UID=1000" >> Dockerfile
   echo "ARG GID=1000" >> Dockerfile
   echo " " >> Dockerfile
   echo "ENV JAVA_OPTS\=\"-Xms512M -Xmx1536M\"" >> Dockerfile
   echo " " >> Dockerfile
   echo "ADD ${jar_name} controller.jar" >> Dockerfile
   echo " " >> Dockerfile
   echo "EXPOSE 8080" >> Dockerfile
   echo "ENTRYPOINT [\"java\", \"-jar\", \"controller.jar\"]" >> Dockerfile
}


build_image () {
   if docker build -t nexquare/controller:latest .
   then
    yellow "Docker imgage created"
   else
    red "Image build failed"
    exit 4
   fi
}

push_image () {
   if docker push nexquare/controller:latest
   then
    yellow "Image pushed"
   else
    red "Push failed"
    exit 5
   fi
}

delete_pod () {
   kubectl delete pod $(kubectl get pods | grep controller | awk '{print $1}')
   yellow "Success ... !!! New pod should be running now"
}

while :
do
clear
    read -p "Enter the new jar file name:" jar_name
    if [ -z $jar_name ]
    then
      red "No jar file name provided"
      exit 3
    else
      update_dockerfile
      build_image      
      push_image
      delete_pod   
    fi
    exit 0  
done
