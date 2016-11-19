#!/bin/sh

set -e

postconf -e "2bounce_notice_recipient = $RELAY_POSTMASTER"
postconf -e "mydomain = $RELAY_MYDOMAIN"
postconf -e "mynetworks = $RELAY_MYNETWORKS"
postconf -e "relayhost = $RELAY_HOST"

if [ -f /etc/postfix/sender_canonical ]; then
  postconf -e "sender_canonical_maps = hash:/etc/postfix/sender_canonical"
  postmap /etc/postfix/sender_canonical
fi

aliases=$(postconf alias_maps |cut -d ':' -f 2)
if [ -f $aliases ]; then
  newaliases
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf
