FROM quay.io/jupyterhub/repo2docker:main

RUN apk add --no-cache curl build-base python3 python3-dev py3-pip

RUN python3 -m pip install --upgrade wheel setuptools

# Manually downgrade version of docker-py
# Until a fix for https://github.com/docker/docker-py/issues/3240
# is released, we want to use an older version of docker-py
RUN pip install 'docker<7.0'

# https://stackoverflow.com/a/41651363/1695486
RUN apk add --no-cache curl curl-dev
COPY create_docker_image.sh /create_docker_image.sh
COPY binder_cache.py /binder_cache.py
COPY trigger_binder.sh /trigger_binder.sh

ENTRYPOINT ["/bin/bash", "/create_docker_image.sh"]

