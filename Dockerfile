FROM alpine:3.8

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
#ENV RELAY_MYHOSTNAME=relay.domain.com
#ENV RELAY_POSTMASTER=postmaster@domain.com
#ENV RELAY_LOGIN=loginname
#ENV RELAY_PASSWORD=xxxxxxxx
#ENV RELAY_TLS_CA=/etc/ssl/ca.crt
#ENV RELAY_EXTRAS_SETTINGS

# Install dependencies
RUN apk --no-cache add \
      cyrus-sasl \
      cyrus-sasl-digestmd5 \
      cyrus-sasl-crammd5 \
      postfix=$POSTFIX_VERSION \
      rsyslog=$RSYSLOG_VERSION \
      supervisor \
    && echo Configuration of main.cf \
    && postconf -e 'notify_classes = bounce, 2bounce, data, delay, policy, protocol, resource, software' \
    && postconf -e 'bounce_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'delay_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'error_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'inet_interfaces = all' \
    && postconf -e 'inet_protocols = all' \
    && postconf -e 'myorigin = $mydomain' \
    && echo SMTPD auth \
    && postconf -e 'smtpd_sasl_auth_enable = yes' \
    && postconf -e 'smtpd_sasl_type = cyrus' \
    && postconf -e 'smtpd_sasl_local_domain = $mydomain' \
    && postconf -e 'smtpd_sasl_security_options = noanonymous' \
    && echo Other configurations \
    && postconf -e 'smtpd_banner = $myhostname ESMTP $mail_name RELAY' \
    && postconf -e 'smtputf8_enable = no' \
    && echo Configuration of sasl2 \
    && mkdir -p /etc/sasl2 \
    && echo 'pwcheck_method: auxprop' > /etc/sasl2/smtpd.conf \
    && echo 'auxprop_plugin: sasldb' >> /etc/sasl2/smtpd.conf \
    && echo 'mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5' >> /etc/sasl2/smtpd.conf

# copy local files
COPY root/ /

RUN  touch /etc/postfix/aliases \
  && touch /etc/postfix/sender_canonical \
  && mkdir -p /data \
  && ln -s /data/sasldb2 /etc/sasldb2

EXPOSE 25/tcp
VOLUME ["/data"]
WORKDIR /data

HEALTHCHECK --interval=5s --timeout=3s --retries=3 \
    CMD nc -zv 127.0.0.1 25 || exit 1

COPY /entrypoint.sh /

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "--configuration", "/etc/supervisord.conf"]
