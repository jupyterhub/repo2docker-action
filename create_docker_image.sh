#!/bin/bash

: ${REGISTRY:=docker.pkg.github.com}
: ${REGISTRY_USERNAME:=$GITHUB_ACTOR}
: ${REGISTRY_PASSWORD:=$GITHUB_TOKEN}

echo "Building binder"
jupyter-repo2docker --no-run --ref $GITHUB_SHA .

#docker login -u="$REGISTRY_USERNAME" -p="$REGISTRY_PASSWORD"
#docker tag IMAGE_ID docker.pkg.github.com/neovintage/notebooks/IMAGE_NAME:VERSION
#docker push docker.pkg.github.com/neovintage/notebooks/IMAGE_NAME:VERSION
