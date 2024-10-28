#!/bin/bash -x

docker build . --build-arg SOURCE_FOLDER=node-hostname -t "local-registry/node-hostname:0.0.1"
