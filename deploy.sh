#!/usr/bin/env bash

## Global settings
# "production" branch
MASTER_BRANCH=${MASTER_BRANCH:-master}

## Local settings
build_tags_file="${PWD}/build.sh~tags"

## Init conditions
# For branch others than the production one, only build one container with the latest glpi version
[ -n "${POSTFIX_VERSION}" -a "${VCS_BRANCH}" != "${MASTER_BRANCH}" ] && exit 0

## Deploy
# Authenticate to docker hub
echo "$DOCKERHUB_REGISTRY_PASSWORD" | docker login --username="$DOCKERHUB_REGISTRY_USERNAME" --password-stdin

# push each built images
for image in `cat "${build_tags_file}"`; do
  echo "-> push ${image}"
  docker push $image
done

# Unauthenticate to docker hub
docker logout
