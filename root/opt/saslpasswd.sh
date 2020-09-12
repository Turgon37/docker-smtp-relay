#!/bin/sh
saslpasswd2 -f /data/sasldb2 -a postfix "$@"
chown postfix:postfix /data/sasldb2
