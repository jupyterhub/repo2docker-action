#!/bin/bash

# exit when any command fails
set -e

# Validate That Required Inputs Were Supplied
function check_env() {
    if [ -z $(eval echo "\$$1") ]; then
        echo "Variable $1 not found.  Exiting..."
        exit 1
    fi
}

check_env "INPUT_DOCKER_USERNAME"
check_env "INPUT_DOCKER_PASSWORD"
check_env "INPUT_IMAGE_NAME"


# Login to Docker registry
echo ${INPUT_DOCKER_PASSWORD} | docker login -u ${INPUT_DOCKER_USERNAME} --password-stdin

# Set Local Variables
shortSHA=$(echo "${GITHUB_SHA}" | cut -c1-12)
SHA_NAME="${INPUT_IMAGE_NAME}:${shortSHA}"

# Run repo2docker
cmd="jupyter-repo2docker --no-run --user-id 1234 --user-name ${GITHUB_ACTOR} --image-name ${SHA_NAME} --ref $GITHUB_SHA ${PWD}"
echo "repo2docker command: $cmd"
eval $cmd
echo "docker push ${SHA_NAME}"
docker push ${SHA_NAME}

# Emit output variables
echo "::set-output name=IMAGE_SHA_NAME::${SHA_NAME}"
echo "::set-output name=IMAGE_URI::https://hub.docker.com/r/${INPUT_IMAGE_NAME}"