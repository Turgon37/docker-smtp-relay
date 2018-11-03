#!/usr/bin/env bash


## Initialization
set -e

image_building_name=`cat ${PWD}/_image_build`


## Prepare
if [[ -z $(which container-structure-test 2>/dev/null) ]]; then
  echo "Retrieving structure-test binary...."
  if [[ "$TRAVIS_OS_NAME" != 'linux' ]]; then
    echo "container-structure-test only released for Linux at this time."
    echo "To run on OSX, clone the repository and build using 'make'."
    exit 1
  else
    curl -LO https://storage.googleapis.com/container-structure-test/latest/container-structure-test-linux-amd64 \
    && chmod +x container-structure-test-linux-amd64 \
    && sudo mv container-structure-test-linux-amd64 /usr/local/bin/container-structure-test
  fi
fi


## Test
container-structure-test \
    test --image "${image_building_name}" --config ./tests.yml
