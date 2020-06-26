FROM jupyter/repo2docker:master

COPY create_docker_image.sh /create_docker_image.sh
COPY binder_cache.py /binder_cache.py
COPY trigger_binder.sh /trigger_binder.sh
RUN chmod u+x trigger_binder.sh

ENTRYPOINT ["/bin/bash", "/create_docker_image.sh"]

