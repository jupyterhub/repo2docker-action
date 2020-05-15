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
REPO_NAME=`echo $GITHUB_REPOSITORY | cut -d "/" -f 2`

# Set image name to username/repo_name if not provided
if [ -z "$INPUT_IMAGE_NAME" ]
then
      INPUT_IMAGE_NAME="$INPUT_DOCKER_USERNAME/$REPO_NAME"
fi

# Prepend image name with registry if it is supplied
if [ "$INPUT_DOCKER_REGISTRY" ]; then
    INPUT_IMAGE_NAME="$INPUT_DOCKER_REGISTRY/$INPUT_IMAGE_NAME"
fi

# Pick username
NB_USER=${NOTEBOOK_USER:-"$GITHUB_ACTOR"}

# Login to Docker registry
echo ${INPUT_DOCKER_PASSWORD} | docker login $INPUT_DOCKER_REGISTRY -u ${INPUT_DOCKER_USERNAME} --password-stdin

# Set Local Variables
shortSHA=$(echo "${GITHUB_SHA}" | cut -c1-12)
SHA_NAME="${INPUT_IMAGE_NAME}:${shortSHA}"

# Attempt to pull the image for a cached build
docker pull "${INPUT_IMAGE_NAME}" 2> /dev/null || true

# Run repo2docker
cmd="jupyter-repo2docker --no-run --user-id 1234 --user-name ${NB_USER} --image-name ${SHA_NAME} --cache-from ${INPUT_IMAGE_NAME} ${PWD}"
echo "repo2docker command: $cmd"
eval $cmd
echo "docker push ${SHA_NAME}"
docker push ${SHA_NAME}

# Emit output variables
echo "::set-output name=IMAGE_SHA_NAME::${SHA_NAME}"
