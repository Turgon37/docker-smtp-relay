#!/bin/sh

set -e

## Configure timezone
if [ -n "${TZ}" ]; then
  echo "Configuring timezone to ${TZ}..."
  if [ ! -f "/usr/share/zoneinfo/${TZ}" ]; then
    echo "...#ERROR# failed to link timezone data from /usr/share/zoneinfo/${TZ}" 1>&2
    exit 1
  fi
  ln -snf "/usr/share/zoneinfo/${TZ}" /etc/localtime
  echo "${TZ}" > /etc/timezone
fi
