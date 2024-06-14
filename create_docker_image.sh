#!/bin/bash

# exit when any command fails
set -e

echo "::group::Validate Information"

if [ "$INPUT_APPENDIX_FILE" ]; then
    APPENDIX=`cat $INPUT_APPENDIX_FILE`
    echo "Appendix read from $INPUT_APPENDIX_FILE:\n$APPENDIX"
fi

# Set INPUT_NO_PUSH to false if it is not provided
if [ -z "$INPUT_NO_PUSH" ]; then
    INPUT_NO_PUSH="false"
fi

# Login to Docker registry if about to push and credentials are passed
if [[ "$INPUT_NO_PUSH" = "false" && -n "$INPUT_DOCKER_PASSWORD" && -n "$INPUT_DOCKER_USERNAME" ]]; then
    echo ${INPUT_DOCKER_PASSWORD} | docker login $INPUT_DOCKER_REGISTRY -u ${INPUT_DOCKER_USERNAME} --password-stdin
fi

REPO_NAME=`echo $GITHUB_REPOSITORY | cut -d "/" -f 2`

# Set image name to username/repo_name or github_actor/repo_name
if [ -z "$INPUT_IMAGE_NAME" ]; then
    if [[ -z "$INPUT_DOCKER_USERNAME" ]]; then
        INPUT_IMAGE_NAME="$GITHUB_ACTOR/$REPO_NAME"
    else
        INPUT_IMAGE_NAME="$INPUT_DOCKER_USERNAME/$REPO_NAME"
    fi

    # Lower-case
    INPUT_IMAGE_NAME="${INPUT_IMAGE_NAME,,}"
fi

# Prepend image name with registry if it is supplied
if [ "$INPUT_DOCKER_REGISTRY" ]; then
    INPUT_IMAGE_NAME="$INPUT_DOCKER_REGISTRY/$INPUT_IMAGE_NAME"
fi

# Set username
if [ -z "$INPUT_NOTEBOOK_USER" ] || [ "$INPUT_MYBINDERORG_TAG" ] || [ "$INPUT_BINDER_CACHE" ];
    then
        NB_USER="jovyan"

    else
        NB_USER="${INPUT_NOTEBOOK_USER}"
fi

# Set REPO_DIR
if [ -z "$INPUT_REPO_DIR" ];
    then
        REPO_DIR="/home/${NB_USER}"
    else
        REPO_DIR="${INPUT_REPO_DIR}"
fi

# Set Local Variables
shortSHA=$(echo "${GITHUB_SHA}" | cut -c1-12)
SHA_NAME="${INPUT_IMAGE_NAME}:${shortSHA}"

# Attempt to pull the image for a cached build
docker pull "${INPUT_IMAGE_NAME}" 2> /dev/null || true
echo "::endgroup::"

# Print variables for debugging
echo "::group::Show Variables"
    echo "DOCKER_REGISTRY": ${INPUT_DOCKER_REGISTRY}
    echo "INPUT_ADDITIONAL_TAG: ${INPUT_ADDITIONAL_TAG}"
    echo "INPUT_APPENDIX_FILE: ${INPUT_APPENDIX_FILE}"
    echo "INPUT_BINDER_CACHE: ${INPUT_BINDER_CACHE}"
    echo "INPUT_IMAGE_NAME: ${INPUT_IMAGE_NAME}"
    echo "INPUT_IMAGE_NAME: ${INPUT_IMAGE_NAME}"
    echo "INPUT_MYBINDERORG_TAG: ${INPUT_MYBINDERORG_TAG}"
    echo "INPUT_MYBINDERORG_TAG: ${INPUT_MYBINDERORG_TAG}"
    echo "INPUT_NOTEBOOK_USER: ${INPUT_NOTEBOOK_USER}"
    echo "INPUT_NO_PUSH: ${INPUT_NO_PUSH}"
    echo "INPUT_PUBLIC_REGISTRY_CHECK: ${INPUT_PUBLIC_REGISTRY_CHECK}"
    echo "INPUT_FORCE_REPO2DOCKER_VERSION: ${INPUT_FORCE_REPO2DOCKER_VERSION}"
    echo "INPUT_REPO_DIR: ${INPUT_REPO_DIR}"
    echo "NB_USER: ${NB_USER}"
    echo "PWD: ${PWD}"
    echo "SHA_NAME: ${SHA_NAME}"
echo "::endgroup::"

echo "IMAGE_SHA_NAME=${SHA_NAME}" >> $GITHUB_OUTPUT
echo "IMAGE_SHA_TAG=${shortSHA}" >> $GITHUB_OUTPUT


echo "::group::Build ${SHA_NAME}"
# Install specific version of repo2docker if required
if [ ! -z "${INPUT_FORCE_REPO2DOCKER_VERSION}" ]; then
    python3 -m pip install --upgrade --force ${INPUT_FORCE_REPO2DOCKER_VERSION}
fi


# If BINDER_CACHE flag is specified, validate user intent by checking for the presence of .binder and binder directories.
if [ "$INPUT_BINDER_CACHE" ]; then
    GENERIC_MSG="This Action assumes you are not explicitly using Binder to build your dependencies."

    # Exit if .binder directory is present
    if [ -d ".binder" ]; then
            echo "Found directory .binder ${GENERIC_MSG} The presence of a directory named .binder indicates otherwise.  Aborting this step.";
            exit 1;
    fi

    # Delete binder directory if it exists and only contains Dockerfile, so repo2docker can do a fresh build.
    if [ -d "binder" ]; then
        # if /binder has files other than Dockerfile, exit with status code 1, else remove the binder folder.
        num_files=`ls binder | grep -v 'Dockerfile' | wc -l`
        if [[ "$num" -gt 0 ]];
            then
                echo "Files other than Dockerfile are present in your binder/ directory. ${GENERIC_MSG} This directory is used by this Action to point to an existing Docker image that Binder can pull.";
                exit 1;
            else
                rm -rf binder
        fi
    fi
fi

# Just build the image, do not push it
# Don't quote ${INPUT_REPO2DOCKER_EXTRA_ARGS}, as it *should* be interpreted as arbitrary
# arguments to be passed to repo2docker.
# Explicitly specify repo and ref labels, as repo2docker only knows it is building something
# local.
jupyter-repo2docker --no-run --user-id 1000 --user-name ${NB_USER} \
    --target-repo-dir ${REPO_DIR} --image-name ${SHA_NAME} --cache-from ${INPUT_IMAGE_NAME} \
    --label "repo2docker.repo=https://github.com/${GITHUB_REPOSITORY}" \
    --label "repo2docker.ref=${GITHUB_REF}" \
    --appendix "$APPENDIX" ${INPUT_REPO2DOCKER_EXTRA_ARGS} ${PWD}

if [ -z "$INPUT_LATEST_TAG_OFF" ]; then
    docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:latest
fi
if [ "$INPUT_ADDITIONAL_TAG" ]; then
    docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:$INPUT_ADDITIONAL_TAG
fi
echo "::endgroup::"

# If a directory named image-tests exists, run tests on the built image
if [ -d "${PWD}/image-tests" ]; then
    echo "::group::Run tests found in image-tests/"
    # We pass in bash that is run inside the built container, so watch out for quoting.
    docker run -u 1000 -w ${REPO_DIR} \
        ${SHA_NAME} /bin/bash -c '
        export PYTEST_FLAGS="";

        # If there is a requirements.txt file inside image-tests, install it.
        # Useful if you want to install a bunch of pytest packages.
        [ -f image-tests/requirements.txt ] && \
            echo "Installing from image-tests/requirements.txt..." && \
            python3 -m pip install --no-cache -r image-tests/requirements.txt;

        # If pytest is not already installed in the image, install it.
        which py.test > /dev/null || \
            echo "Installing pytest inside the image..." && \
            python3 -m pip install --no-cache pytest > /dev/null;

        # If there are any .ipynb files in image-tests, install pytest-notebook
        # if necessary, and set PYTEST_FLAGS so notebook tests are run.
        ls image-tests/*.ipynb > /dev/null && \
            echo "Found notebooks, using pytest-notebook to run them..." && \
            export PYTEST_FLAGS="--nb-test-files ${PYTEST_FLAGS}" && \
            python3 -c "import pytest_notebook" 2> /dev/null || \
                python3 -m pip install --no-cache pytest-notebook > /dev/null;

        py.test ${PYTEST_FLAGS} image-tests/
    '
    echo "::endgroup::"
fi

if [ "$INPUT_NO_PUSH" = "false" ]; then
    echo "::group::Pushing ${SHA_NAME}"

	docker push ${SHA_NAME}

    if [ -z "$INPUT_LATEST_TAG_OFF" ]; then
        docker push ${INPUT_IMAGE_NAME}:latest
    fi
    if [ "$INPUT_ADDITIONAL_TAG" ]; then
        docker push ${INPUT_IMAGE_NAME}:$INPUT_ADDITIONAL_TAG
    fi

    echo "::endgroup::"

    echo "PUSH_STATUS=true" >> $GITHUB_OUTPUT

    if [ "$INPUT_PUBLIC_REGISTRY_CHECK" ]; then
        echo "::group::Verify That Image Is Public"
        docker logout
        if docker pull $SHA_NAME; then
            echo "Verified that $SHA_NAME is publicly visible."
        else
            echo "Could not pull docker image: $SHA_NAME.  Make sure this image is public before proceeding."
            exit 1
        fi
        echo "::endgroup::"
    fi

else
    if [ "$INPUT_NO_PUSH" != "true" ]; then
        echo "Error: invalid value for NO_PUSH: $INPUT_NO_PUSH. Valid values are true or false."
        exit 1
    fi

    echo "PUSH_STATUS=false" >> $GITHUB_OUTPUT
fi

if [ "$INPUT_BINDER_CACHE" ]; then
    echo "::group::Commit Local Dockerfile For Binder Cache"
    python3 /binder_cache.py "$SHA_NAME"
    git config --global --add safe.directory /github/workspace
    git config --global user.email "github-actions[bot]@users.noreply.github.com"
    git config --global user.name "github-actions[bot]"
    git add binder/Dockerfile
    if [ "$INPUT_COMMIT_MSG" ]; then
        git commit -m"${INPUT_COMMIT_MSG}"
    else
        git commit -m'Update image tag'
    fi
    if [ ! "$INPUT_NO_GIT_PUSH" ]; then
        git push -f
    fi
    echo "::endgroup::"
fi


if [ "$INPUT_MYBINDERORG_TAG" ]; then
    echo "::group::Triggering Image Build on mybinder.org"
    /trigger_binder.sh "https://gke.mybinder.org/build/gh/$GITHUB_REPOSITORY/$INPUT_MYBINDERORG_TAG"
    echo "::endgroup::"
fi
