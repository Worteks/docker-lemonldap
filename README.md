# SweetLemonLDAP

LemonLDAP-NG, customized to load its configuration from an LDAP backend,
shipping with Sweet custom theme, loosly based on
https://github.com/LemonLDAPNG/lemonldap-ng-docker

Diverts from https://github.com/Worteks/docker-apache

Depends on SweeLDAP - https://github.com/Worteks/docker-ldap. You would need
to pass your OpenLDAP host address for lemon to start up, as LemonLDAP core
configuration would refer to that LDAP storing the rest of its configuration.

```
git clone github.com/Worteks/docker-ldap
cd docker-ldap
make build demo
```

Build with:
```
$ make build
```

Test with:
```
$ docker run -e OPENLDAP_ROOT_DOMAIN=demo.local \
    -e OPENLDAP_LEMONLDAP_PASSWORD=secret -e OPENLDAP_BIND_LDAP_PORT=389 \
    -e OPENLDAP_DEMO_PASSWORD=demo -p 389:389 -p 636:636 wsweet/openldap
$ docker run -e OPENLDAP_BIND_PW=secret -e OPENLDAP_DOMAIN=demo.local \
    -e OPENLDAP_HOST=172.17.0.2 -e LLNG_HTTP_PORT=8080 \
    --add-host=auth.demo.local:127.0.0.1 \
    --add-host=portal.demo.local:127.0.0.1 \
    --add-host=manager.demo.local:127.0.0.1 \
    --add-host=reload.demo.local:127.0.0.1 \
    --add-host=test1.demo.local:127.0.0.1 \
    --add-host=test2.demo.local:127.0.0.1 \
    -p 8080:8080 wsweet/lemon
$ make run
```

Start Demo or Cluster in OpenShift:

```
$ make ocdemo
$ make ocprod
```

Cleanup OpenShift assets:

```
$ make ocpurge
```

Hosts overrides
---------------

Prefer adding the following records to your `/etc/hosts`. These may be set by
passing the `--add-host=NAME:127.0.0.1` to the Docker `run` command.

|     VirtualHost             |
| :-------------------------: |
|  `auth.OPENLDAP_DOMAIN`     |
|  `portal.OPENLDAP_DOMAIN`   |
|  `manager.OPENLDAP_DOMAIN`  |
|  `reload.OPENLDAP_DOMAIN`   |
|  `test1.OPENLDAP_DOMAIN`    |
|  `test2.OPENLDAP_DOMAIN`    |

Environment variables and volumes
----------------------------------

The image recognizes the following environment variables that you can set during
initialization by passing `-e VAR=VALUE` to the Docker `run` command.

|    Variable name           |    Description                | Default                                                     | Inherited From |
| :------------------------- | ----------------------------- | ----------------------------------------------------------- | -------------- |
|  `APACHE_DOMAIN`           | Apache ServerName             | `example.com`                                               | wsweet/apache  |
|  `APACHE_IGNORE_OPENLDAP`  | Ignore LemonLDAP autoconf     | undef                                                       | wsweet/apache  |
|  `GIT_SSH_PORT`            | SSH Port cloning LLNG Themes  | `22`                                                        |                |
|  `LEMON_CUSTOM_THEMES`     | LemonLDAP Customer Themes     | undef                                                       |                |
|  `LLNG_PROTO`              | Public LLNG Proto             | undef, assumes `http`                                       |                |
|  `LLNG_HTTP_PORT`          | LemonLDAP HTTP(s) Port        | `8080`                                                      |                |
|  `LLNG_PUB_PORT`           | LemonLDAP Public HTTP Port    | `80`                                                        |                |
|  `OPENLDAP_BASE`           | OpenLDAP Base                 | seds `OPENLDAP_DOMAIN`, default produces `dc=demo,dc=local` | wsweet/apache  |
|  `OPENLDAP_BIND_DN_RREFIX` | OpenLDAP Bind DN Prefix       | `cn=lemonldap,ou=services`                                  | wsweet/apache  |
|  `OPENLDAP_BIND_PW`        | OpenLDAP Bind Password        | `secret`                                                    | wsweet/apache  |
|  `OPENLDAP_CONF_DN_RREFIX` | OpenLDAP Conf DN Prefix       | `cn=lemonldap,ou=config`                                    | wsweet/apache  |
|  `OPENLDAP_DOMAIN`         | OpenLDAP Domain Name          | undef                                                       | wsweet/apache  |
|  `OPENLDAP_HOST`           | OpenLDAP Backend Address      | undef                                                       | wsweet/apache  |
|  `OPENLDAP_PORT`           | OpenLDAP Bind Port            | `389` or `636` depending on `OPENLDAP_PROTO`                | wsweet/apache  |
|  `OPENLDAP_PROTO`          | OpenLDAP Proto                | `ldap`                                                      | wsweet/apache  |


|  Volume mount point                     | Description                                                                     | Inherited From |
| :-------------------------------------- | ------------------------------------------------------------------------------- | -------------- |
|  `/.ssh/id_rsa`                         | Optional Input Private Key setting up LemonLDAP-NG Themes                       |                |
|  `/etc/lemonldap-ng`                    | LemonLDAP-NG Configuration                                                      |                |
|  `/etc/lib/lemonldap-ng/notifications`  | LemonLDAP-NG Notifications Storage                                              |                |
|  `/var/apache-secrets`                  | Apache Secrets root - install server.crt, server.key and ca.crt to enable https | wsweet/apache  |
|  `/vhosts`                              | Apache VirtualHosts templates root - processed during container start           | wsweet/apache  |

Themes
------

Note that the LemonLDAP deployment may eventually be configured shipping with
custom themes. Doing so, we would create a Git repository, create an SSH key
pair, define our public key as a "deploy key" in our Git repository settings,
define our private key as a secret in the corresponding OpenShift project,
and insert that secret into our LemonLDAP deploymentconfiguration.

First create our keypair and secret:

```
$ ssh-keygen -t rsa -b 4096
[...]
$ oc create secret generic lemon-themes-wsweet --from-file=id_rsa=path/to/id_rsa
$ oc edit dc/lemon-wsweet
[...]
      - env:
        - name: GIT_SSH_PORT
          value: "2222"
        - name: LEMON_CUSTOM_THEMES
          value: git+ssh://git.example.com/proj/repo.git
[...]
        volumeMounts:
        - name: git-clone-ssh
          mountPath: /.ssh/id_rsa
          subPath: id_rsa
[...]
      volumes:
      - secret:
          mode: 420
          secretName: lemon-themes-wsweet
        name: git-clone-ssh
[...]
```

When done and redeployed (check the logs, you should see you files being take
care of), switch LemonLDAP::NG to "custom" theme in the manager
