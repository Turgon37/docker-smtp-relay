#!/usr/bin/env bash


## Global settings
# image name
DOCKER_IMAGE="${DOCKER_REPO:-smtp-relay}"
# "production" branch
PRODUCTION_BRANCH=${PRODUCTION_BRANCH:-master}


## Initialization
set -e

if [[ ${DOCKER_IMAGE} =~ ([^/]+)/([^/]+) ]]; then
  username=${BASH_REMATCH[1]}
  repo=${BASH_REMATCH[2]}
  echo "-> set username to '${username}'"
  echo "-> set repository to '${repo}'"
else
  echo 'ERROR: unable to extract username and repo from environment' 1>&2
  exit 1
fi

if [[ -z "$DOCKERHUB_REGISTRY_USERNAME" || -z "$DOCKERHUB_REGISTRY_PASSWORD" ]]; then
  echo 'ERROR: missing one of the registry credential DOCKERHUB_REGISTRY_USERNAME DOCKERHUB_REGISTRY_PASSWORD' 1>&2
  exit 1
fi

image_version=`cat VERSION`

if [[ -n ${IMAGE_VARIANT} ]]; then
  image_building_name="${DOCKER_IMAGE}:building_${IMAGE_VARIANT}"
  image_tags_prefix="${IMAGE_VARIANT}-"
  echo "-> set image variant '${IMAGE_VARIANT}' for build"
else
  image_building_name="${DOCKER_IMAGE}:building"
fi
echo "-> use image name '${image_building_name}' for publish"

application_version=`docker inspect -f '{{ index .Config.Labels "application.postfix.version"}}' ${image_building_name}`

if [[ -z "$GLPI_VERSION" ]]; then
  # no fixed application version => latest build
  image_tags="latest ${application_version}-latest"
fi

# If empty branch, fetch the current from local git rpo
if [[ -n "${SOURCE_BRANCH}" ]]; then
  VCS_BRANCH="${SOURCE_BRANCH}"
elif [[ -n "${TRAVIS_BRANCH}" ]]; then
  VCS_BRANCH="${TRAVIS_BRANCH}"
else
  VCS_BRANCH="`git rev-parse --abbrev-ref HEAD`"
fi
test -n "${VCS_BRANCH}"
echo "-> current vcs branch '${VCS_BRANCH}'"

# set the docker tag prefix if needed
if [ "${VCS_BRANCH}" != "${PRODUCTION_BRANCH}" ]; then
  image_tags_prefix="${VCS_BRANCH}-${image_tags_prefix}"
  echo "-> use tag prefix '${image_tags_prefix}'"
fi

# customs tags
image_tags="${image_tags} ${application_version}-${image_version}"
echo "-> use image tags '${image_tags}'"

# finals
image_final_tags=()
for tag in $image_tags; do
  image_final_tags+=("${image_tags_prefix}${tag}")
done
image_final_tags=`echo -n "${image_final_tags[*]}" | tr ' ' '\n' | uniq | tr '\n' ' '`
echo "-> use final image tags list '${image_final_tags}'"

## Enforce versioning
for tag in $image_final_tags; do
  if echo "$tag" | grep -q "$image_version"; then
    echo "-? check if image version '$image_version' already exists in registry"
    if curl -s "https://hub.docker.com/v2/repositories/${username}/${repo}/tags/?page_size=100" | grep -q '"name": "'${tag}'"'; then
      echo "ERROR: Tag '${tag}' for image version '$image_version' already exists in registry" 1>&2
      exit 0
    fi
  fi
done

## Login to registry
echo "$DOCKERHUB_REGISTRY_PASSWORD" | docker login --username="$DOCKERHUB_REGISTRY_USERNAME" --password-stdin

## Push images
for tag in $image_final_tags; do
  echo "=> tag image '${image_building_name}' as '${DOCKER_IMAGE}:${tag}'"
  docker tag "${image_building_name}" "${DOCKER_IMAGE}:${tag}"
  echo "=> push image '${DOCKER_IMAGE}:${tag}'"
  docker push "${DOCKER_IMAGE}:${tag}"
done

## Logout from registry
docker logout
