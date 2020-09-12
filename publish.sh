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

image_version=$(cat VERSION)
image_building_name="${DOCKER_IMAGE}:building"
echo "-> use image name '${image_building_name}' for publish"

# If empty branch, fetch the current from local git rpo
if [[ -n "${SOURCE_BRANCH}" ]]; then
  VCS_BRANCH="${SOURCE_BRANCH}"
elif [[ -n "${TRAVIS_BRANCH}" ]]; then
  VCS_BRANCH="${TRAVIS_BRANCH}"
else
  VCS_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
fi
test -n "${VCS_BRANCH}"
echo "-> current vcs branch '${VCS_BRANCH}'"

# set the docker publish logic per branch
application_version=$(docker inspect -f '{{ index .Config.Labels "application.postfix.version" }}' "${image_building_name}")
publish=false
if [[ "${VCS_BRANCH}" == "${PRODUCTION_BRANCH}" ]]; then
  image_tags=(latest "${application_version}-latest" "${application_version}-${image_version}")
  if ! curl -s "https://hub.docker.com/v2/repositories/${username}/${repo}/tags/?page_size=100" \
       | grep --quiet "\"name\": *\"${application_version}-${image_version}\""; then
    publish=true
  fi
elif [[ "${VCS_BRANCH}" == "develop" ]]; then
  image_tags=(develop-latest "develop-${application_version}-${image_version}")
  publish=true
fi
echo "-> use image tags '${image_tags[*]}'"


## Publish image
if [[ "${publish}" != "true" ]]; then
  echo "-> No need to Push to Registry"
else
  echo "-> Pushing to registry.."

  ## Login to registry
  echo "$DOCKERHUB_REGISTRY_PASSWORD" | docker login --username="$DOCKERHUB_REGISTRY_USERNAME" --password-stdin

  ## Push images
  for tag in ${image_tags[*]}; do
    echo "=> tag image '${image_building_name}' as '${DOCKER_IMAGE}:${tag}'"
    docker tag "${image_building_name}" "${DOCKER_IMAGE}:${tag}"
    echo "=> push image '${DOCKER_IMAGE}:${tag}'"
    docker push "${DOCKER_IMAGE}:${tag}"
  done

  ## Logout from registry
  docker logout
fi


## Publish README
# only for production branch
if [[ "${VCS_BRANCH}" == "${PRODUCTION_BRANCH}" && -n "${UPDATE_README}" ]]; then
  set -o pipefail
  TOKEN=$(curl --fail --silent -H "Content-Type: application/json" -X POST -d "{\"username\": \"${DOCKERHUB_REGISTRY_USERNAME}\", \"password\": \"${DOCKERHUB_REGISTRY_PASSWORD}\"}" https://hub.docker.com/v2/users/login/ | grep --perl-regexp --only-matching '(?<=token": ")[^"]+')
  curl --fail --silent -H "Authorization: JWT $TOKEN" -X PATCH "https://hub.docker.com/v2/repositories/${username}/${repo}/" --data-urlencode full_description@./README.md
  set +o pipefail
fi
