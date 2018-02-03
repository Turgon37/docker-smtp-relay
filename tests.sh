#!/usr/bin/env bash

## Local settings
build_tags_file="${PWD}/build.sh~tags"
docker_run_options='--detach'

## Settings initialization
set -e
set -x

source ${PWD}/_tools.sh

## Tests

#1 Test build successful
echo '-> 1 Test build successful'
[ -f "${build_tags_file}" ]

# Get main image
echo '-> Get main image'
image=`head --lines=1 "${build_tags_file}"`

#2 Test if Postfix successfully installed
echo '-> 2 Test if postfix successfully installed'
image_name=postfix_2
docker run --rm $docker_run_options --name "${image_name}" "${image}" which postfix
