#!/bin/bash

# exit when any command fails
set -e

echo "::group::Validate Information"  

# Validate That Required Inputs Were Supplied
function check_env() {
    if [ -z $(eval echo "\$$1") ]; then
        echo "Variable $1 not found.  Exiting..."
        exit 1
    fi
}

if [ -z "$INPUT_NO_PUSH" ]; then
    check_env "INPUT_DOCKER_USERNAME"
    check_env "INPUT_DOCKER_PASSWORD"
    # Login to Docker registry
    echo ${INPUT_DOCKER_PASSWORD} | docker login $INPUT_DOCKER_REGISTRY -u ${INPUT_DOCKER_USERNAME} --password-stdin
fi

REPO_NAME=`echo $GITHUB_REPOSITORY | cut -d "/" -f 2`

# Set image name to username/repo_name if not provided
if [ -z "$INPUT_IMAGE_NAME" ]; then
    INPUT_IMAGE_NAME="$INPUT_DOCKER_USERNAME/$REPO_NAME"
fi

# Prepend image name with registry if it is supplied
if [ "$INPUT_DOCKER_REGISTRY" ]; then
    INPUT_IMAGE_NAME="$INPUT_DOCKER_REGISTRY/$INPUT_IMAGE_NAME"
fi

# Set username
NB_USER=${INPUT_NOTEBOOK_USER:-"$GITHUB_ACTOR"}

# Set Local Variables
shortSHA=$(echo "${GITHUB_SHA}" | cut -c1-12)
SHA_NAME="${INPUT_IMAGE_NAME}:${shortSHA}"

# Attempt to pull the image for a cached build
docker pull "${INPUT_IMAGE_NAME}" 2> /dev/null || true
echo "::endgroup::"

if [ -z "$INPUT_NO_PUSH" ]; then
    echo "::group::Build and Push ${SHA_NAME}" 
        jupyter-repo2docker --push --no-run --user-id 1234 --user-name ${NB_USER} --image-name ${SHA_NAME} --cache-from ${INPUT_IMAGE_NAME} ${PWD}

        if [ -z "$INPUT_LATEST_TAG_OFF" ]; then
            docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:latest
            docker push ${INPUT_IMAGE_NAME}:latest
        fi
        if [ "$INPUT_ADDITIONAL_TAG" ]; then
            docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:$INPUT_ADDITIONAL_TAG
            docker push ${INPUT_IMAGE_NAME}:$INPUT_ADDITIONAL_TAG
        fi
        
    echo "::endgroup::"

    echo "::set-output name=IMAGE_SHA_NAME::${SHA_NAME}"
    echo "::set-output name=PUSH_STATUS::true"

    if [ "$INPUT_PUBLIC_REGISTRY_CHECK" ]; then
        docker logout
        if docker pull  $SHA_NAME &>/dev/null; then
            echo "Verified that $SHA_NAME is publicly visible."
        else
            echo "Could not pull docker image: $SHA_NAME.  Make sure this image is public before proceeding."
            exit 1
        fi
    fi

else
    echo "::group::Build Image Without Pushing" 
        jupyter-repo2docker --no-run --user-id 1234 --user-name ${NB_USER} --image-name ${SHA_NAME} --cache-from ${INPUT_IMAGE_NAME} ${PWD}
        if [ -z "$INPUT_LATEST_TAG_OFF" ]; then
            docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:latest
        fi
        if [ "$INPUT_ADDITIONAL_TAG" ]; then
            docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:$INPUT_ADDITIONAL_TAG
        fi
    echo "::endgroup::"
    echo "::set-output name=PUSH_STATUS::false"
fi


if [ "$INPUT_BINDER_CACHE" ]; then
    python binder_cache.py "$SHA_NAME"
    git config --global user.email "github-actions[bot]@users.noreply.github.com"
    git config --global user.name "github-actions[bot]"
    git add binder/Dockerfile
    git commit -m'update registry tagname'
    git push -f
fi


if [ "$INPUT_MYBINDERORG_TAG" ]; then
    check_env "MYBINDERORG_TAG"
    ./trigger_binder.sh https://gke.mybinder.org/build/gh/$GITHUB_REPOSITORY/$MYBINDERORG_TAG
fi
