#!/bin/bash
set -euo pipefail

# THIS FILE IS FOR LOCAL TESTING

docker build -t github/repo2docker-test .

INPUT_DOCKER_REGISTRY_USERNAME="${DOCKER_USERNAME}"
INPUT_DOCKER_REGISTRY_PASSWORD="${DOCKER_PASSWORD}"
INPUT_IMAGE_NAME="github/repo2docker-test"
GITHUB_SHA="c0d285f7eef547b16b28fece79a866894db08c04"

# This container builds the container with repo2docker
docker run \
--workdir /github/workspace \
-e INPUT_DOCKER_USERNAME=$INPUT_DOCKER_REGISTRY_USERNAME \
-e INPUT_DOCKER_PASSWORD=$INPUT_DOCKER_REGISTRY_PASSWORD \
-e INPUT_IMAGE_NAME=$INPUT_IMAGE_NAME \
-e GITHUB_SHA=${GITHUB_SHA} \
-v ${PWD}:/github/workspace \
github/repo2docker-test
