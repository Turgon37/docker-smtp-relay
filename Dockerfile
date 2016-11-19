FROM alpine:3.4
MAINTAINER Pierre GINDRAUD <pgindraud@gmail.com>

ENV RELAY_POSTMASTER postmaster@domain.com
ENV RELAY_MYDOMAIN domain.com
ENV RELAY_MYNETWORKS 127.0.0.0/8
ENV RELAY_HOST [127.0.0.1]:25


# Install dependencies
RUN echo "http://dl-cdn.alpinelinux.org/alpine/edge/main/" >> /etc/apk/repositories && \
    echo "http://dl-cdn.alpinelinux.org/alpine/edge/community/" >> /etc/apk/repositories && \
    apk --no-cache add \
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
    
    postconf -e 'smtpd_sasl_auth_enable = yes' && \
    postconf -e 'smtpd_sasl_type = cyrus' && \
    postconf -e 'smtpd_sasl_local_domain = $mydomain' && \
    postconf -e 'smtpd_sasl_security_options = noanonymous' && \

    #postconf -e smtpd_banner="\$myhostname ESMTP" && \
    #postconf -e relayhost=[smtp.gmail.com]:587 && \ 
    #postconf -e smtp_sasl_auth_enable=yes && \
    #postconf -e smtp_sasl_password_maps=hash:/etc/postfix/sasl_passwd && \
    #postconf -e smtp_sasl_security_options=noanonymous && \
    #postconf -e smtp_tls_CAfile=/etc/postfix/cacert.pem && \
    #postconf -e smtp_use_tls=yes && \

# Configuration of sasl2
    echo 'pwcheck_method: auxprop' && \
    echo 'auxprop_plugin: sasldb' && \
    echo 'mech_list: PLAIN LOGIN CRAM-MD5 DIGEST-MD5'

COPY rsyslog.conf /etc/rsyslog.conf
COPY start.sh /start.sh
COPY supervisord.conf /etc/supervisord.conf

RUN echo '' > /etc/postfix/aliases && \
    chmod +x /start.sh

EXPOSE 25

CMD ["/start.sh"]
