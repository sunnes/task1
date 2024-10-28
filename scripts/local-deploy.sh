#!/bin/bash -x

app="node-hostname"
version="$1"

helm upgrade $app chart --atomic --create-namespace --namespace $app --timeout 60s --set "version=${version}"
