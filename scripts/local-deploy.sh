#!/bin/bash -x

app="node-hostname"

version="$1"
if [ -n "$1" ]; then
  version="--set image.tag=$1"
fi

helm upgrade $app chart --atomic --create-namespace --namespace $app --timeout 45s ${version}
