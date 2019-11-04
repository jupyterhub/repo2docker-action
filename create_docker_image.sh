#!/bin/bash

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

# IF optional DOCKER_REGISTRY not supplied, revert to default registry.hub.docker.com
if [ ! -z "$INPUT_DOCKER_REGISTRY" ]; then
    echo "Different Registry Provided: $INPUT_DOCKER_REGISTRY"
    DOCKER_REGISTRY=$INPUT_DOCKER_REGISTRY
else
    DOCKER_REGISTRY="registry.hub.docker.com"
fi

# Login to Docker registry
echo ${INPUT_DOCKER_PASSWORD} | docker login -u ${INPUT_DOCKER_USERNAME} --password-stdin $DOCKER_REGISTRY


# GitHub's Docker Registry Requires You to prepend the owner/repo to the image name
if [ "$DOCKER_REGISTRY" == "docker.pkg.github.com" ]; then
    BASE_NAME="${DOCKER_REGISTRY}/${GITHUB_REPOSITORY}/${INPUT_IMAGE_NAME}"
else
    BASE_NAME="${INPUT_IMAGE_NAME}"
fi

# Set Local Variables
shortSHA=$(echo "${GITHUB_SHA}" | cut -c1-12)
SHA_NAME="${BASE_NAME}:${shortSHA}"

# Run repo2docker
cmd="jupyter-repo2docker --no-run --user-id 1234 --user-name ${GITHUB_ACTOR} --image-name ${SHA_NAME} --ref $GITHUB_SHA ${PWD}"
echo "repo2docker command: $cmd"
jupyter-repo2docker --no-run --user-id 1234 --user-name $INPUT_DOCKER_USERNAME --ref $GITHUB_SHA .
docker push ${SHA_NAME}

# Emit output variables
echo "::set-output name=IMAGE_SHA_NAME::${SHA_NAME}"