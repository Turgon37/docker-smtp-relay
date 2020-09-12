# Docker SMTP Relay

[![Build Status](https://travis-ci.com/Turgon37/docker-smtp-relay.svg?branch=master)](https://travis-ci.com/Turgon37/docker-smtp-relay)
[![](https://images.microbadger.com/badges/image/turgon37/smtp-relay.svg)](https://microbadger.com/images/turgon37/smtp-relay "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/turgon37/smtp-relay.svg)](https://microbadger.com/images/turgon37/smtp-relay "Get your own version badge on microbadger.com")

This image contains an instance of Postfix SMTP server configured as a SMTP relay.
This relay is restricted to only one domain name. so it means that only mail that come from RELAY_MYDOMAIN will be relayed to the relayhost.

:warning: Take care of the [changelogs](CHANGELOG.md) because some breaking changes may happend between versions.

## Supported tags, image variants and respective Dockerfile links

* main image with postfix [Dockerfile](https://github.com/Turgon37/docker-smtp-relay/blob/master/Dockerfile)

    * `latest`


## Example of usage

This relay can take place into a information system if you want to give access to some web or other applications a way to send notification by mail.

The advantage of this configuration is that only the host in theses case are allowed to send emails through this relay :

* The host IP's address is in the range of RELAY_MYNETWORKS
* The host is authenticated with a valid SASL login/password

## Docker Informations

* This port is available on this image

| Port | Usage                        |
| ---- | ---------------------------- |
| 25   | SMTP for incoming relay user |

* This volume is bind on this image

| Volume             | Usage                                                                                        |
| ------------------ | -------------------------------------------------------------------------------------------- |
| /data              | Contains the flat database that contains all SASL user                                       |
| /var/spool/postfix | Where postfix store mail queue (to persist not yet delivered mails across container restart) |

* This image takes theses environnements variables as parameters

| Environment                  | Type                 | Usage                                                                                                                                                           |
| ---------------------------- | -------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| RELAY_MYHOSTNAME             | String               | The hostname of the SMTP relay (because docker assign a random hostname, you can specify here a human-readable hostname)                                        |
| RELAY_MYDOMAIN   (mandatory) | String               | The domain name that this relay will forward the mail                                                                                                           |
| RELAY_MYNETWORKS             | List of strings      | The space separated list of network(s) which are allowed by default to relay emails                                                                             |
| RELAY_DOMAINS                | List of strings      | The space separated list of external domain names for whose this relay will forward email. Useless if you use a *NODOMAIN relay mode. Default to RELAY_MYDOMAIN |
| RELAY_HOST       (mandatory) | String               | The remote host to which send the relayed emails (the relayhost)                                                                                                |
| RELAY_LOGIN                  | String               | The login name to present to the relayhost during authentication (optional)                                                                                     |
| RELAY_PASSWORD               | String               | The password to present to the relayhost during authentication (optional)                                                                                       |
| RELAY_USE_TLS                | Boolean(yes/no)      | Specify if you want to require a TLS connection to relayhost                                                                                                    |
| RELAY_TLS_VERIFY             | Enum                 | How to verify the TLS  : (none, may, encrypt, dane, dane-only, fingerprint, verify, secure)                                                                     |
| RELAY_TLS_CA                 | String path          | The path (in the container) to the CA file use to check relayhost certificate (Default: `/etc/ssl/certs/ca-certificates.crt`)                                   |
| RELAY_POSTMASTER             | String email address | The email address of the postmaster, in order to send error, and misconfiguration notification                                                                  |
| RELAY_STRICT_SENDER_MYDOMAIN | Boolean(true/false)  | If set to 'true' all sender addresses must belong to the relay domains                                                                                          |
| RELAY_MODE                   | Enum                 | The predefined mode of relay behaviour, theses modes has been designed by me. See below for available values                                                    |
| RELAY_EXTRAS_SETTINGS        | List of string       | (deprecated use POSTCONF_ below) Space separated of extras options that will be passed to postconf -e                                                           |
| POSTCONF_[custom]            | Mixed                | Set any available postconf value (see example below)                                                                                                            |


### Relay Mode

Description of available relay modes

| Relay mode value        | Description                                                                                                                                                                                                                                                            | Usage                                                                                                                                                                                 |
| ----------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| STRICT                  | Only network and sasl authenticated users can send emails through relay. All emails must have a recipient adress which belong to the relay domains                                                                                                                     | Typically you can use this mode to allow one of your application to send email to internals domain emails adresses                                                                    |
| ALLOW_SASLAUTH_NODOMAIN | Only network and sasl authenticated users can send emails through relay. All emails send by network authenticated users must have a recipient adress which belong to the relay domains. All emails send by sasl authenticated users can have any recipient adress(es). | You can use this mode to allow one of your (internal) application to send email to external users. In case when some part(s) of your application will be reachable by externals users |
| ALLOW_NETAUTH_NODOMAIN  | Only network and sasl authenticated users can send emails through relay. All emails send by sasl authenticated users must have a recipient adress which belong to the relay domains. All emails send by network authenticated users can have any recipient adress(es)  |                                                                                                                                                                                       |
| ALLOW_AUTH_NODOMAIN     | Only network and sasl authenticated users can send emails through relay. All emails send by all authenticated users can have any recipient adress(es).                                                                                                                 | In case where you want a simple relay host with a basic auth                                                                                                                          |

For other examples of values, you can refer to the Dockerfile


## Todo

* Improve smtp healthcheck
* Add prometheus exporters (https://github.com/engage-ehs/rsyslog_exporter https://github.com/kumina/postfix_exporter)


## Installation

* Manual

```bash
git clone
./build.sh
```

* or Automatic

```bash
docker pull turgon37/smtp-relay
```

## Usage

```bash
docker run -p 25:25 -e "RELAY_MYDOMAIN=domain.com" -e "RELAY_HOST=relay:25" turgon37/smtp-relay
```

### Docker-compose Specific configuration examples

* unauthenticated smtp relay filtered by subnet and domain name

```yaml
services:
  smtp-relay:
    image: turgon37/smtp-relay:latest
    environment:
      RELAY_POSTMASTER: 'postmaster@example.net'
      RELAY_MYHOSTNAME: 'smtp-relay.example.net'
      RELAY_MYDOMAIN: 'example.net'
      RELAY_MYNETWORKS: '127.0.0.0/8 10.0.0.0/24'
      RELAY_HOST: '[10.1.0.1]:25'
    ports:
      - "10.0.0.1:3000:25"
```

* authenticated smtp proxy

```yaml
services:
  smtp-relay-auth:
    image: turgon37/smtp-relay:latest
    environment:
      RELAY_POSTMASTER: 'postmaster@example.net'
      RELAY_MYHOSTNAME: 'smtp-relay.example.net'
      RELAY_MYDOMAIN: 'example.net'
      RELAY_MYNETWORKS: '127.0.0.0/8 10.0.0.0/24'
      RELAY_HOST: '[10.1.0.1]:25'
      RELAY_MODE: 'ALLOW_SASLAUTH_NODOMAIN'
      RELAY_LOGIN: 'sasl-user-login'
      RELAY_PASSWORD: 'xxxxxxxxxxxx'
      RELAY_USE_TLS: 'no'
      POSTCONF_compatibility_level: '2'
    ports:
      - "10.0.0.1:3000:25"
    volumes:
      - data-smtp-relay-auth:/data
      - data-smtp-relay-queue:/var/spool/postfix
volumes:
  data-smtp-relay-auth:
  data-smtp-relay-queue:
```

### Using external relay credentials

If you want to prevent having your relay credentials in your docker-compose file, you can mount them (instead of setting
`RELAY_LOGIN`and `RELAY_PASSWORD` variables) into `/etc/postfix/sasl_passwd`

Taking again our `authenticated smtp proxy` example above, we would now have:

```yaml
services:
  smtp-relay-auth:
    image: turgon37/smtp-relay:latest
    environment:
      RELAY_POSTMASTER: 'postmaster@example.net'
      RELAY_MYHOSTNAME: 'smtp-relay.example.net'
      RELAY_MYDOMAIN: 'example.net'
      RELAY_MYNETWORKS: '127.0.0.0/8 10.0.0.0/24'
      RELAY_HOST: '[10.1.0.1]:25'
      RELAY_MODE: ALLOW_SASLAUTH_NODOMAIN
      RELAY_USE_TLS: 'no'
      POSTCONF_compatibility_level: '2'
    ports:
      - "10.0.0.1:3000:25"
    volumes:
      - data-smtp-relay-auth:/data
      - "/my/local/path/sasl_passwd:/etc/postfix/sasl_passwd"
volumes:
  data-smtp-relay-auth:
```

And our local `sasl_passwd` file would have as contents:

```bash
user@host:~$cat /my/local/path/sasl_passwd
[10.1.0.1]:25 sasl-user-login:xxxxxxxxxxxx  
```

### Configuration during runtime

* List all SASL users :

```bash
docker exec smtp-relay /opt/listpasswd.sh
```

* Add a SASL user :

If you have a host which is not in the range of addresses specified in 'mynetworks' of postfix, this host have to be sasl authenticated when it connects to the smtp relay.

To create a generic account for this host you have to run this command into the container

```bash
docker exec -it smtp-relay /opt/saslpasswd.sh -u domain.com -c username
```

You have to replace domain.com with your relay domain and you will be prompt for password two times. Then you will be prompted for password two times

* Add multiple SASL users :

If you want to add multiple sasl users at the same time you can mount (-v) your credentials list to /etc/postfix/client_sasl_passwd
This list must contains one credential per line and for each line use the syntax  'USERNAME PASSWORD'  (the username and the password are separated with a blank space)

You can check with docker logs if all of your line has been correctly parsed


### Troubleshooting

An simple SMTP client is embedded with this image. You can use it to test your settings

```
docker exec -it smtp-relay /opt/smtp_client.py -s test -f noreply@domain.com --user user1:password1 admin@domain.com
```
