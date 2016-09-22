#!/bin/bash

## This bash script is called on 'docker run' command. 
## If used, it must be overriden in a volume.

echo "docker-init: no commands specified"

## Sensible data can be handled with docker-init.conf :
#source /opt/docker/docker-init.conf
## Examples:
#echo "Datbase name: $db_name"
#echo "Datbase password: $db_password"