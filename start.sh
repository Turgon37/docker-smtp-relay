#!/bin/sh

set -e

# Set configuration according to ENV
postconf -e "mydomain = $RELAY_MYDOMAIN"
postconf -e "mynetworks = $RELAY_MYNETWORKS"
postconf -e "relayhost = $RELAY_HOST"

# Set hostname
if [ -n "$RELAY_MYHOSTNAME" ]; then
  postconf -e "myhostname = $RELAY_MYHOSTNAME"
fi

# Set default postmaster value
if [ -z "$RELAY_POSTMASTER" ]; then
  RELAY_POSTMASTER="postmaster@$RELAY_MYDOMAIN"
fi
postconf -e "2bounce_notice_recipient = $RELAY_POSTMASTER"

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
if [ -n "$RELAY_LOGIN" -a -n "$RELAY_PASSWORD" ]; then
  postconf -e 'smtp_sasl_auth_enable = yes'
  # use password from hash database
  if [ -f /etc/postfix/sasl_passwd ]; then
    postconf -e 'smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd'
    postmap /etc/postfix/sasl_passwd
  else
   # use static database
    postconf -e "smtp_sasl_password_maps = static:{$RELAY_LOGIN:$RELAY_PASSWORD}"
  fi
  postconf -e 'smtp_sasl_security_options = noanonymous'
  
  if [ -n "$RELAY_USE_TLS" -a "$RELAY_USE_TLS" = 'yes' -a -z "$RELAY_TLS_CA" ]; then
    echo "you must fill RELAY_TLS_CA with the path to the CA file in the container" >&2
	exit 1
  fi
  postconf -e "smtp_tls_CAfile = $RELAY_TLS_CA"
  postconf -e "smtp_tls_security_level = $RELAY_TLS_VERIFY"
  postconf -e 'smtp_tls_session_cache_database = btree:${data_directory}/smtp_scache'
  postconf -e "smtp_use_tls = $RELAY_USE_TLS"
fi

postconf -e "smtpd_sender_restrictions = check_sender_access inline:{$RELAY_MYDOMAIN=OK}, reject"

# Fill the sasl user database with seed
if [ -f /etc/postfix/client_sasl_passwd ]; then
  [ ! -r /etc/postfix/client_sasl_passwd ] && {
	echo "client_sasl_passwd database is not readable" >&2
	exit 1
  }
  for peer in "$(cat /etc/postfix/client_sasl_passwd)"; do
    $user=$(echo "$peer" | cut -d \  -f 1)
    $pass=$(echo "$peer" | cut -d \  -f 2)
    echo $pass | saslpasswd2 -p -u $RELAY_MYDOMAIN -c $user
    echo "...registered user $user into sasl database"
  done
fi

exec /usr/bin/supervisord -c /etc/supervisord.conf
