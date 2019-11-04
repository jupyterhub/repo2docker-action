FROM jupyter/repo2docker:master

# It is a mystery to me how docker is NOT installed in the repo2docker container?
RUN apk add docker

COPY create_docker_image.sh /create_docker_image.sh
ENTRYPOINT ["/bin/bash", "/create_docker_image.sh"]

