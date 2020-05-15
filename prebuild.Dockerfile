FROM jupyter/repo2docker:master

# It is a mystery to me how docker is NOT installed in the repo2docker container?
RUN apk add docker
# build this with: docker build -t github/repo2docker -f prebuild.Dockerfile .