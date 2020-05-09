# Changelog

Items starting with `DEPRECATE` are important deprecation notices.

## 3.2.0 (2020-05-09)

+ Update alpine to 3.11
+ Split entrypoint tasks into separated files
+ Update rsyslog config to new syntax
+ Update supervisord config
+ Use postfix start-fg command to run postfix
+ Add missing package for timezone to work
+ Add postconf entrypoint hook from POSTCONF_* variables
+ Fix #17 sasl_client bulk feed (thanks @mattstrain) #17
+ Fix sasl passwd list command

### Build process

+ Add shellcheck tests
+ Prevent overwrite /etc permissions during COPY

### Deprecation

- DEPRECATE RELAY_EXTRAS_SETTINGS settings in favor of POSTCONF_ variables (will be removed in 4.0)


## 3.1.0 (2019-09-09)

### Image

- Allow use of external users database (thanks to @kir4h)
- Update alpine to 3.10
- Refactor the entrypoint.sh
- Update supervisor configuration


## 3.0.1 (2019-05-23)

### Image

- Image has now a default value for `RELAY_TLS_CA` (thanks to @kir4h)


## 3.0.0 (2019-03-30)

### Image

- Replace start.sh by entrypoint


## 2.2.0 (2018-11-03)

### Image

+ Upgrade base image to Alpine 3.8


## 2.1.0 (2018-03-31)

### Image

+ Add docker healthcheck command


## 2.0.0 (2018-02-03)

### Image

+ Add RELAY_EXTRAS_SETTINGS setting
+ Upgrade base image to Alpine 3.7

### Sasl

* Moved the utility scripts to /opt/postfix


## 1.0.0 (2017-05-27)

First release
