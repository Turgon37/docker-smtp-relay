#!/usr/bin/env bash

## Global settings
# image name
DOCKER_IMAGE="${DOCKER_REPO:-smtp-relay}"
# use dockefile
DOCKERFILE_PATH=Dockerfile

## Initialization
set -e

## Local settings
alpine_version=$(grep --perl-regexp --only-matching '(?<=FROM alpine:)[0-9.]+' Dockerfile)
arch=$(uname --machine)

## Settings initialization
set -e

# If empty version, fetch the latest from repository
if [[ -z "$POSTFIX_VERSION" ]]; then
  POSTFIX_VERSION=$(curl -s "https://pkgs.alpinelinux.org/packages?name=postfix&branch=v${alpine_version}&repo=main&arch=${arch}" \
                     | grep --perl-regexp --only-matching '(?<=<td class="version">)[a-z0-9.-]+' | uniq)
  # no postfix fixed version => latest build
  image_tags="${image_tags} latest"
  test -n "$POSTFIX_VERSION"
fi
echo "-> selected Postfix version '${POSTFIX_VERSION}'"

# If empty version, fetch the latest from repository
if [[ -z "$RSYSLOG_VERSION" ]]; then
  RSYSLOG_VERSION=$(curl -s "https://pkgs.alpinelinux.org/packages?name=rsyslog&branch=v${alpine_version}&repo=main&arch=${arch}" \
                     | grep --perl-regexp --only-matching '(?<=<td class="version">)[a-z0-9.-]+' | uniq)
  test -n "$RSYSLOG_VERSION"
fi
echo "-> selected Rsyslog version '${RSYSLOG_VERSION}'"

# If empty commit, fetch the current from local git rpo
if [[ -n "${SOURCE_COMMIT}" ]]; then
  VCS_REF="${SOURCE_COMMIT}"
elif [[ -n "${TRAVIS_COMMIT}" ]]; then
  VCS_REF="${TRAVIS_COMMIT}"
else
  VCS_REF="$(git rev-parse --short HEAD)"
fi
test -n "${VCS_REF}"
echo "-> current vcs reference '${VCS_REF}'"

# Get the current image static version
image_version=$(cat VERSION)
echo "-> use image version '${image_version}'"

# Compute variant from dockerfile name
if ! [[ -f ${DOCKERFILE_PATH} ]]; then
  echo 'You must select a valid dockerfile with DOCKERFILE_PATH' 1>&2
  exit 1
fi

image_building_name="${DOCKER_IMAGE}:building"
echo "-> use image name '${image_building_name}' for build"

## Build image
echo "=> building '${image_building_name}' with image version '${image_version}'"
docker build --build-arg "POSTFIX_VERSION=${POSTFIX_VERSION}" \
             --build-arg "RSYSLOG_VERSION=${RSYSLOG_VERSION}" \
             --label "org.label-schema.build-date=$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
             --label 'org.label-schema.name=smtp-relay' \
             --label 'org.label-schema.description=SMTP server configured as a email relay' \
             --label 'org.label-schema.url=https://github.com/Turgon37/docker-smtp-relay' \
             --label "org.label-schema.vcs-ref=${VCS_REF}" \
             --label 'org.label-schema.vcs-url=https://github.com/Turgon37/docker-smtp-relay' \
             --label 'org.label-schema.vendor=Pierre GINDRAUD' \
             --label "org.label-schema.version=${image_version}" \
             --label 'org.label-schema.schema-version=1.0' \
             --label "application.postfix.version=${POSTFIX_VERSION}" \
             --label "application.rsyslog.version=${RSYSLOG_VERSION}" \
             --tag "${image_building_name}" \
             --file "${DOCKERFILE_PATH}" \
             .
