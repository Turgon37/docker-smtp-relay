#!/usr/bin/env bash

## Global settings
# docker hub username
DOCKER_USERNAME="${DOCKERHUB_REGISTRY_USERNAME:-turgon37}"
# image name
DOCKER_IMAGE="${DOCKER_USERNAME}/${DOCKER_IMAGE:-smtp-relay}"
# "production" branch
MASTER_BRANCH=${MASTER_BRANCH:-master}

## Local settings
build_tags_file="${PWD}/build.sh~tags"
docker_tag_prefix=
alpine_version=`cat Dockerfile | grep --perl-regexp --only-matching '(?<=FROM alpine:)[0-9.]+'`
arch=`uname --machine`

## Settings initialization
set -e
set -x

# If empty version, fetch the latest from repository
if [ -z "$POSTFIX_VERSION" ]; then
  POSTFIX_VERSION=`curl -s "https://pkgs.alpinelinux.org/packages?name=postfix&branch=v${alpine_version}&repo=main&arch=${arch}" | grep --perl-regexp --only-matching '(?<=<td class="version">)[a-z0-9.-]+' | uniq`
  if [ -z "$DOCKER_IMAGE_TAGS" ]; then
    DOCKER_IMAGE_TAGS="${DOCKER_IMAGE_TAGS} latest"
  fi
fi
echo "-> selected Postfix version ${POSTFIX_VERSION}"

# If empty version, fetch the latest from repository
if [ -z "$RSYSLOG_VERSION" ]; then
  RSYSLOG_VERSION=`curl -s "https://pkgs.alpinelinux.org/packages?name=rsyslog&branch=v${alpine_version}&repo=main&arch=${arch}" | grep --perl-regexp --only-matching '(?<=<td class="version">)[a-z0-9.-]+' | uniq`
fi
echo "-> selected Rsyslog version ${RSYSLOG_VERSION}"

# If empty version, fetch the latest from repository
if [ -z "$VCS_REF" ]; then
  VCS_REF=`git rev-parse --short HEAD`
fi
echo "-> current vcs reference ${VCS_REF}"

# Set the docker image tag prefix
if [ "${VCS_BRANCH}" != "${MASTER_BRANCH}" ]; then
  docker_tag_prefix="${VCS_BRANCH}-"
fi
echo "-> working with tags prefix ${docker_tag_prefix}"

echo "-> working with tags ${DOCKER_IMAGE_TAGS}"

image_version=`cat VERSION`
echo "-> building ${DOCKER_IMAGE} with image version: ${image_version}"

## Build image
docker build --build-arg VCS_REF="${VCS_REF}" \
             --build-arg IMAGE_VERSION="$image_version" \
             --build-arg POSTFIX_VERSION="$POSTFIX_VERSION" \
             --build-arg RSYSLOG_VERSION="$RSYSLOG_VERSION" \
             --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
             --tag "${DOCKER_IMAGE}:${docker_tag_prefix}${POSTFIX_VERSION}" \
             --file Dockerfile \
             .

## Image taaging
echo "${DOCKER_IMAGE}:${docker_tag_prefix}${POSTFIX_VERSION}" > ${build_tags_file}

# Tag images
for tag in $DOCKER_IMAGE_TAGS; do
  if [ -n "$tag" ]; then
    docker tag "${DOCKER_IMAGE}:${docker_tag_prefix}${POSTFIX_VERSION}" "${DOCKER_IMAGE}:${docker_tag_prefix}${tag}"
    echo "${DOCKER_IMAGE}:${docker_tag_prefix}${tag}" >> ${build_tags_file}
  fi
done

echo "-> produced following image names"
cat "${build_tags_file}"
