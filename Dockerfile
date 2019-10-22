FROM jupyter/repo2docker:0.10.0

COPY create_docker_image.sh /create_docker_image.sh
ENTRYPOINT ["/create_docker_image.sh"]
