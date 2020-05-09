#!/bin/sh

set -e

DIR=/docker-entrypoint.d

if [ -d "$DIR" ]; then
  /bin/run-parts --exit-on-error "$DIR" 1>&2
fi

exec "$@"
