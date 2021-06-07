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

if [ "$INPUT_APPENDIX_FILE" ]; then
    APPENDIX=`cat $INPUT_APPENDIX_FILE`
    echo "Appendix read from $INPUT_APPENDIX_FILE: $APPENDIX"
fi

if [ -z "$INPUT_NO_PUSH" ]; then
    check_env "INPUT_DOCKER_USERNAME"
    check_env "INPUT_DOCKER_PASSWORD"
    # Login to Docker registry
    echo ${INPUT_DOCKER_PASSWORD} | docker login $INPUT_DOCKER_REGISTRY -u ${INPUT_DOCKER_USERNAME} --password-stdin
fi

REPO_NAME=`echo $GITHUB_REPOSITORY | cut -d "/" -f 2`

# Set Docker username to the actor name not provided
if [ -z "$INPUT_DOCKER_USERNAME" ]; then
    INPUT_DOCKER_USERNAME="$GITHUB_ACTOR"
fi

# Set image name to username/repo_name if not provided
if [ -z "$INPUT_IMAGE_NAME" ]; then
    INPUT_IMAGE_NAME="$INPUT_DOCKER_USERNAME/$REPO_NAME"
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
    echo "INPUT_BINDER_CACHE: ${INPUT_BINDER_CACHE}"
    echo "INPUT_IMAGE_NAME: ${INPUT_IMAGE_NAME}"
    echo "INPUT_IMAGE_NAME: ${INPUT_IMAGE_NAME}"
    echo "INPUT_MYBINDERORG_TAG: ${INPUT_MYBINDERORG_TAG}"
    echo "INPUT_MYBINDERORG_TAG: ${INPUT_MYBINDERORG_TAG}"
    echo "INPUT_NOTEBOOK_USER: ${INPUT_NOTEBOOK_USER}"
    echo "INPUT_NO_PUSH: ${INPUT_NO_PUSH}"
    echo "INPUT_PUBLIC_REGISTRY_CHECK: ${INPUT_PUBLIC_REGISTRY_CHECK}"
    echo "INPUT_REPO_DIR: ${INPUT_REPO_DIR}"
    echo "NB_USER: ${NB_USER}"
    echo "PWD: ${PWD}"
    echo "SHA_NAME: ${SHA_NAME}"
echo "::endgroup::"

if [ -z "$INPUT_NO_PUSH" ]; then
    echo "::group::Build and Push ${SHA_NAME}"
        

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

        jupyter-repo2docker --push --no-run --user-id 1000 --user-name ${NB_USER} --target-repo-dir ${REPO_DIR} --image-name ${SHA_NAME} --cache-from ${INPUT_IMAGE_NAME} --appendix $APPENDIX

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
    echo "::group::Build Image Without Pushing" 
        jupyter-repo2docker --no-run --user-id 1000 --user-name ${NB_USER} --target-repo-dir ${REPO_DIR} --image-name ${SHA_NAME} --cache-from ${INPUT_IMAGE_NAME} --appendix ${APPENDIX} ${PWD}
        if [ -z "$INPUT_LATEST_TAG_OFF" ]; then
            docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:latest
        fi
        if [ "$INPUT_ADDITIONAL_TAG" ]; then
            docker tag ${SHA_NAME} ${INPUT_IMAGE_NAME}:$INPUT_ADDITIONAL_TAG
        fi
    echo "::endgroup::"
    echo "::set-output name=PUSH_STATUS::false"/
fi


if [ "$INPUT_BINDER_CACHE" ]; then
    echo "::group::Commit Local Dockerfile For Binder Cache" 
    python /binder_cache.py "$SHA_NAME"
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
