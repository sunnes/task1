#!/bin/bash -x

if [ -z "$1" ]; then
    docker build . --build-arg SOURCE_FOLDER=node-hostname -t "local-registry/node-hostname:0.0.1"
else
    docker build . --build-arg SOURCE_FOLDER=node-hostname -t "local-registry/node-hostname:${1}"
fi