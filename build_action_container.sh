#!/bin/bash

docker build -t github/repo2docker-action .
docker tag github/repo2docker-action github/repo2docker-action:latest
docker push github/repo2docker-action
docker push github/repo2docker-action:latest
