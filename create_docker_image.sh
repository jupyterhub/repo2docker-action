#!/bin/bash

: ${REGISTRY:=docker.pkg.github.com}
: ${REGISTRY_USERNAME:=$GITHUB_ACTOR}
: ${REGISTRY_PASSWORD:=$GITHUB_TOKEN}

echo "Building binder"
ls -al
jupyter-repo2docker --no-run --ref $GITHUB_SHA .

