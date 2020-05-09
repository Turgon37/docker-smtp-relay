#!/usr/bin/env bash

## Global settings
# image name
DOCKER_IMAGE="${DOCKER_REPO:-smtp-relay}"

## Initialization
set -e

image_building_name="${DOCKER_IMAGE}:building"
docker_run_options='--detach'
echo "-> use image name '${image_building_name}' for tests"


## Prepare
if [[ -z $(command -v container-structure-test 2>/dev/null) ]]; then
  echo "Retrieving structure-test binary...."
  if [[ -n "${TRAVIS_OS_NAME}" && "$TRAVIS_OS_NAME" != 'linux' ]]; then
    echo "container-structure-test only released for Linux at this time."
    echo "To run on OSX, clone the repository and build using 'make'."
    exit 1
  else
    curl -sS -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 \
    && chmod +x container-structure-test-linux-amd64 \
    && mv container-structure-test-linux-amd64 container-structure-test
  fi
fi

# Download tools shim.
if [[ ! -f _tools.sh ]]; then
  curl -L -o "${PWD}/_tools.sh" https://gist.github.com/Turgon37/2ba8685893807e3637ea3879ef9d2062/raw
fi
# shellcheck disable=SC1090
source "${PWD}/_tools.sh"


## Test
# shell scripts tests
# shellcheck disable=SC2038
find . -name '*.sh' | xargs shellcheck docker-entrypoint.d/*

# Image tests
./container-structure-test \
    test --image "${image_building_name}" --config ./tests.yml


#2 Test timezone setting
echo '-> 2 Test timezone'
image_name=smtp_2
docker run $docker_run_options --name "${image_name}" --env='TZ=Europe/Paris' "${image_building_name}"
wait_for_string_in_container_logs "${image_name}" 'connect from localhost'
# test
if ! [[ $(docker exec "${image_name}" readlink -f /etc/localtime) =~ Europe/Paris$ ]]; then
  docker logs "${image_name}"
  false
fi
stop_and_remove_container "${image_name}"
