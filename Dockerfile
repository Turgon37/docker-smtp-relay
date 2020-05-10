#
# Final stage for image
#
FROM alpine:3.11

LABEL maintainer='Pierre GINDRAUD <pgindraud@gmail.com>'

ARG POSTFIX_VERSION
ARG RSYSLOG_VERSION

ENV RELAY_MYDOMAIN=domain.com
ENV RELAY_MYNETWORKS=127.0.0.0/8
ENV RELAY_HOST=[127.0.0.1]:25
ENV RELAY_USE_TLS=yes
ENV RELAY_TLS_VERIFY=may
ENV RELAY_DOMAINS=\$mydomain
ENV RELAY_STRICT_SENDER_MYDOMAIN=true
ENV RELAY_MODE=STRICT
ENV RELAY_TLS_CA /etc/ssl/certs/ca-certificates.crt
#ENV RELAY_MYHOSTNAME=relay.domain.com
#ENV RELAY_POSTMASTER=postmaster@domain.com
#ENV RELAY_LOGIN=loginname
#ENV RELAY_PASSWORD=xxxxxxxx
#ENV RELAY_EXTRAS_SETTINGS

ENV POSTCONF_inet_interfaces all
ENV POSTCONF_inet_protocols ipv4

# Install dependencies
RUN apk --no-cache add \
      cyrus-sasl \
      cyrus-sasl-crammd5 \
      cyrus-sasl-digestmd5 \
      cyrus-sasl-login \
      cyrus-sasl-plain \
      postfix=$POSTFIX_VERSION \
      rsyslog=$RSYSLOG_VERSION \
      supervisor \
      tzdata

# Configuration of main.cf
RUN postconf -e 'notify_classes = bounce, 2bounce, data, delay, policy, protocol, resource, software' \
    && postconf -e 'bounce_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'delay_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'error_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'myorigin = $mydomain' \
    && postconf -e 'smtpd_sasl_auth_enable = yes' \
    && postconf -e 'smtpd_sasl_type = cyrus' \
    && postconf -e 'smtpd_sasl_local_domain = $mydomain' \
    && postconf -e 'smtpd_sasl_security_options = noanonymous' \
    && postconf -e 'smtpd_banner = $myhostname ESMTP $mail_name RELAY' \
    && postconf -e 'smtputf8_enable = no' \
    && mkdir -p /etc/sasl2 \
    && echo 'pwcheck_method: auxprop' >/etc/sasl2/smtpd.conf \
    && echo 'auxprop_plugin: sasldb' >>/etc/sasl2/smtpd.conf \
    && echo 'mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5' >>/etc/sasl2/smtpd.conf \
    && echo 'sasldb_path: /data/sasldb2' >>/etc/sasl2/smtpd.conf \
    && echo 'log_level: 2' >>/etc/sasl2/smtpd.conf

# Add some configurations files
COPY /root/etc/* /etc/
COPY /root/opt/* /opt/
COPY /docker-entrypoint.sh /
COPY /docker-entrypoint.d/* /docker-entrypoint.d/

RUN chmod -R +x /docker-entrypoint.d/ \
  && touch /etc/postfix/aliases \
  && touch /etc/postfix/sender_canonical \
  && mkdir -p /data

EXPOSE 25/tcp
VOLUME ["/data","/var/spool/postfix"]
WORKDIR /data

HEALTHCHECK --interval=5s --timeout=2s --retries=3 \
    CMD nc -znvw 1 127.0.0.1 25 || exit 1

ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["/usr/bin/supervisord", "--configuration", "/etc/supervisord.conf"]
