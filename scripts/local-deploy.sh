#!/bin/bash -x

app="node-hostname"

helm upgrade $app chart --atomic --create-namespace --namespace $app --timeout 60s
