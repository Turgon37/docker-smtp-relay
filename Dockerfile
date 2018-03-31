FROM alpine:3.7

ARG POSTFIX_VERSION
ARG RSYSLOG_VERSION
ARG IMAGE_VERSION
ARG BUILD_DATE
ARG VCS_REF

LABEL maintainer="Pierre GINDRAUD <pgindraud@gmail.com>" \
      org.label-schema.build-date="${BUILD_DATE}" \
      org.label-schema.name="SMTP server configured as a email relay" \
      org.label-schema.description="This image contains the reliable postfix smtp server configured to be " \
      org.label-schema.url="https://github.com/Turgon37/docker-smtp-relay" \
      org.label-schema.vcs-ref="${VCS_REF}" \
      org.label-schema.vcs-url="https://github.com/Turgon37/docker-smtp-relay" \
      org.label-schema.vendor="Pierre GINDRAUD" \
      org.label-schema.version="${IMAGE_VERSION}" \
      org.label-schema.schema-version="1.0" \
      application.postfix.version="${POSTFIX_VERSION}" \
      application.rsyslog.version="${RSYSLOG_VERSION}" \
      image.version="${IMAGE_VERSION}"

ENV RELAY_MYDOMAIN=domain.com \
    RELAY_MYNETWORKS=127.0.0.0/8 \
    RELAY_HOST=[127.0.0.1]:25 \
    RELAY_USE_TLS=yes \
    RELAY_TLS_VERIFY=may \
    RELAY_DOMAINS=\$mydomain \
    RELAY_STRICT_SENDER_MYDOMAIN=true \
    RELAY_MODE=STRICT
    #RELAY_MYHOSTNAME=relay.domain.com
    #RELAY_POSTMASTER=postmaster@domain.com
    #RELAY_LOGIN=loginname
    #RELAY_PASSWORD=xxxxxxxx
    #RELAY_TLS_CA=/etc/ssl/ca.crt
    #RELAY_EXTRAS_SETTINGS


# Install dependencies
RUN apk --no-cache add \
      cyrus-sasl \
      cyrus-sasl-digestmd5 \
      cyrus-sasl-crammd5 \
      postfix=$POSTFIX_VERSION \
      rsyslog=$RSYSLOG_VERSION \
      supervisor \

# Configuration of main.cf
    && postconf -e 'notify_classes = bounce, 2bounce, data, delay, policy, protocol, resource, software' \
    && postconf -e 'bounce_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'delay_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'error_notice_recipient = $2bounce_notice_recipient' \
    && postconf -e 'inet_interfaces = all' \
    && postconf -e 'inet_protocols = all' \
    && postconf -e 'myorigin = $mydomain' \
# SMTPD auth
    && postconf -e 'smtpd_sasl_auth_enable = yes' \
    && postconf -e 'smtpd_sasl_type = cyrus' \
    && postconf -e 'smtpd_sasl_local_domain = $mydomain' \
    && postconf -e 'smtpd_sasl_security_options = noanonymous' \
# Other configurations
    && postconf -e 'smtpd_banner = $myhostname ESMTP $mail_name RELAY' \
    && postconf -e 'smtputf8_enable = no' \

# Configuration of sasl2
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
    CMD nc -zv 127.0.0.1 27 || exit 1

CMD ["/start.sh"]
