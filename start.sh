#!/bin/sh

set -e

# Set configuration according to ENV
postconf -e "2bounce_notice_recipient = $RELAY_POSTMASTER"
postconf -e "mydomain = $RELAY_MYDOMAIN"
postconf -e "mynetworks = $RELAY_MYNETWORKS"
postconf -e "relayhost = $RELAY_HOST"

# Update the sender mapping databases
if [ -f /etc/postfix/sender_canonical ]; then
  postconf -e "sender_canonical_maps = hash:/etc/postfix/sender_canonical"
  postmap /etc/postfix/sender_canonical
fi

# Update the aliases database
aliases=$(postconf alias_maps |cut -d ':' -f 2)
if [ -f $aliases ]; then
  newaliases
fi

# Configure authentification to relay if needed
if [ -n $RELAY_LOGIN ] && [ -n $RELAY_PASSWORD ]; then
  postconf -e 'smtp_sasl_auth_enable = yes'
  postconf -e "smtp_sasl_password_maps = static:$RELAY_LOGIN:$RELAY_PASSWORD"
  #postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd && \
  postconf -e 'smtp_sasl_security_options = noanonymous'
  postconf -e "smtp_tls_CAfile = /etc/ssl/certs/ca-certificates.crt"
  postconf -e "smtp_tls_security_level = $RELAY_TLS_VERIFY"
  postconf -e 'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache'
  postconf -e "smtp_use_tls = $RELAY_USE_TLS"
fi


exec /usr/bin/supervisord -c /etc/supervisord.conf
