FROM quay.io/jupyterhub/repo2docker:main

RUN apk add --no-cache curl build-base python3 python3-dev py3-pip

RUN python3 -m pip install --upgrade \
        wheel \
        setuptools \
        # FIXME: docker is pinned until a release newer than 7.0.0 is out to
        #        avoid an already fixed but not released regression with too
        #        strict validation of docker tags. Check for newer releases at
        #        https://github.com/docker/docker-py/releases.
        "docker==6.*"

# https://stackoverflow.com/a/41651363/1695486
RUN apk add --no-cache curl curl-dev
COPY create_docker_image.sh /create_docker_image.sh
COPY binder_cache.py /binder_cache.py
COPY trigger_binder.sh /trigger_binder.sh

ENTRYPOINT ["/bin/bash", "/create_docker_image.sh"]

