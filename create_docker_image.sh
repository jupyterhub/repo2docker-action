#!/bin/bash

: ${REGISTRY:=docker.pkg.github.com}
: ${REGISTRY_USERNAME:=$GITHUB_ACTOR}
: ${REGISTRY_PASSWORD:=$GITHUB_TOKEN}


echo "Building binder"
jupyter-repo2docker --no-run --user-name $GITHUB_ACTOR --ref $GITHUB_SHA .
