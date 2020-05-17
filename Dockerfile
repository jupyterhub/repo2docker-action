FROM jupyter/repo2docker:master

COPY create_docker_image.sh /create_docker_image.sh
ENTRYPOINT ["/bin/bash", "/create_docker_image.sh"]

