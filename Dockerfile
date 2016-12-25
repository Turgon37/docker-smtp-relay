FROM alpine:3.4
MAINTAINER Pierre GINDRAUD <pgindraud@gmail.com>

ENV RELAY_MYDOMAIN=domain.com \
    RELAY_MYNETWORKS=127.0.0.0/8 \
    RELAY_HOST=[127.0.0.1]:25 \
    RELAY_USE_TLS=yes \
    RELAY_TLS_VERIFY=may
    #RELAY_MYHOSTNAME=relay.domain.com
    #RELAY_POSTMASTER=postmaster@domain.com
    #RELAY_LOGIN=loginname
    #RELAY_PASSWORD=xxxxxxxx
    #RELAY_TLS_CA=/etc/ssl/ca.crt


# Install dependencies
RUN apk --no-cache add \
    cyrus-sasl cyrus-sasl-digestmd5 cyrus-sasl-crammd5 \
    postfix \
    supervisor \
    rsyslog && \

# Configuration of main.cf
    postconf -e 'notify_classes = bounce, 2bounce, data, delay, policy, protocol, resource, software' && \
    postconf -e 'bounce_notice_recipient = $2bounce_notice_recipient' && \
    postconf -e 'delay_notice_recipient = $2bounce_notice_recipient' && \
    postconf -e 'error_notice_recipient = $2bounce_notice_recipient' && \
    postconf -e 'inet_interfaces = all' && \
    postconf -e 'inet_protocols = all' && \
    postconf -e 'myorigin = $mydomain' && \
    postconf -e 'relay_domains = $mydomain' && \
# SMTPD auth
    postconf -e 'smtpd_sasl_auth_enable = yes' && \
    postconf -e 'smtpd_sasl_type = cyrus' && \
    postconf -e 'smtpd_sasl_local_domain = $mydomain' && \
    postconf -e 'smtpd_sasl_security_options = noanonymous' && \
# Static restrictions for smtp clients
    postconf -e 'smtpd_relay_restrictions = reject_unauth_destination, permit_mynetworks, permit_sasl_authenticated, reject' && \
# Other configurations
    postconf -e 'smtpd_banner = $myhostname ESMTP $mail_name RELAY' && \
    postconf -e 'smtputf8_enable = no' && \

# Configuration of sasl2
    mkdir -p /etc/sasl2/ && \
    echo 'pwcheck_method: auxprop' > /etc/sasl2/smtpd.conf && \
    echo 'auxprop_plugin: sasldb' >> /etc/sasl2/smtpd.conf && \
    echo 'mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5' >> /etc/sasl2/smtpd.conf

COPY rsyslog.conf /etc/rsyslog.conf
COPY start.sh /start.sh
COPY supervisord.conf /etc/supervisord.conf

RUN echo '' > /etc/postfix/aliases && \
    echo '' > /etc/postfix/sender_canonical && \
    chmod +x /start.sh

EXPOSE 25
VOLUME ["/etc/sasldb2"]

CMD ["/start.sh"]
