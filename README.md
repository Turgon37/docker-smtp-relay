# Docker SMTP Relay

[![](https://images.microbadger.com/badges/image/turgon37/smtp-relay.svg)](https://microbadger.com/images/turgon37/smtp-relay "Get your own image badge on microbadger.com")

[![](https://images.microbadger.com/badges/version/turgon37/smtp-relay.svg)](https://microbadger.com/images/turgon37/smtp-relay "Get your own version badge on microbadger.com")

This image contains a instance of Postfix SMTP server configured as a SMTP relay.
This relay is restricted to only one domain name. so it means that only mail that come from RELAY_MYDOMAIN will be relayed to the relayhost.

### Example of usage

This relay can take place into a information system if you want to give access to some web or other applications a way to send notification by mail.

The advantage of this configuration is that only the host in theses case are allowed to send mails through this relay :

   * The host IP's address is in the range of RELAY_MYNETWORKS
   * The host is authenticated with a valid SASL login/password



## Docker Informations

   * This port is available on this image

| Port              | Usage                                        |
| ----------------- | ---------------                              |
| 25                | SMTP for incoming relay user                 |

   * This volume is bind on this image

| Volume        | Usage                                         |
| ------------- | ---------------                               |
| /etc/sasldb2  | The flat database that contains all SASL user |


  * This image takes theses environnements variables as parameters


| Environnement                | Usage                                                                                                                   |
| ---------------------------- | --------------------------------------------------------                                                                |
| RELAY_MYHOSTNAME             | The hostname of the SMTP relay (because docker assign a random hostname, you can specify here a human-readable hostname)|
| RELAY_MYDOMAIN   (mandatory) | The domain name that this relay will forward the mail                                                                   |
| RELAY_MYNETWORKS             | The list of network(s) which are allowed by default to relay mails                                                      |
| RELAY_HOST       (mandatory) | The remote host to which send the relayed mails (the relayhost)                                                         |
| RELAY_LOGIN                  | The login name to present to the relayhost during authentication (optionnal)                                            |
| RELAY_PASSWORD               | The password to present to the relayhost during authentication (optionnal)                                              |
| RELAY_USE_TLS                | Specify if you want to require a TLS connection to relayhost                                                            |
| RELAY_TLS_VERIFY             | How to verify the TLS  : (none, may, encrypt, dane, dane-only, fingerprint, verify, secure)                             |
| RELAY_TLS_CA                 | The path to the CA file use to check relayhost certificate (path in the container)                                      |
| RELAY_POSTMASTER             | The email address of the postmaster, in order to send error, and misconfiguration notification                          |

For example of values, you can refer to the Dockerfile

## Installation

```
git clone
docker build -t docker-smtp-relay .
```

## Usage

```
docker run -p 25:25 -e "RELAY_MYDOMAIN=domain.com" -e "RELAY_HOST=relay:25" docker-smtp-relay
```

### Configuration during running

   * Add a SASL user :

If you have a host which is not in the range of addresses specified in 'mynetworks' of postfix, this host have to be sasl authenticated when it connects to the smtp relay.

To create a generic account for this host you have to run this command into the container

```
saslpasswd2 -u domain.com -c username
```

You have to replace domain.com with your relay domain and you will be prompt for password two time.


   * Add multiple SASL users : 

If you want to add multiple sasl users at the same time you can mount (-v) your credentials list to /etc/postfix/client_sasl_passwd
This list must contains one credential per line and for each line use the syntax  'USERNAME PASSWORD'  (the username and the password are separated with a blank space)

You can check with docker logs if all of your line has been correctly parsed
