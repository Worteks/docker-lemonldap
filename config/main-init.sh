if test "$DEBUG"; then
    APACHE_LOG_LEVEL=perl:debug
    set -x
else
    APACHE_LOG_LEVEL=notice
fi
. /usr/local/bin/nsswrapper.sh
if test "$DEBUG"; then
    echo INFO: running as `id -a`
fi

OPENLDAP_BIND_DN_PREFIX=${OPENLDAP_BIND_DN_PREFIX:-'cn=lemonldap,ou=services'}
OPENLDAP_BIND_PW=${OPENLDAP_BIND_PW:-'secret'}
OPENLDAP_CONF_DN_PREFIX=${OPENLDAP_CONF_DN_PREFIX:-'ou=lemonldap,ou=config'}
OPENLDAP_DOMAIN=${OPENLDAP_DOMAIN:-'demo.local'}
OPENLDAP_HOST=${OPENLDAP_HOST:-'127.0.0.1'}
OPENLDAP_PROTO=${OPENLDAP_PROTO:-'ldap'}
if test -z "$OPENLDAP_BASE"; then
    OPENLDAP_BASE=`echo "dc=$OPENLDAP_DOMAIN" | sed 's|\.|,dc=|g'`
fi
if test -z "$OPENLDAP_PORT" -a "$OPENLDAP_PROTO" = ldaps; then
    OPENLDAP_PORT=636
elif test -z "$OPENLDAP_PORT"; then
    OPENLDAP_PORT=389
fi

LLNG_HTTP_PORT=${LLNG_HTTP_PORT:-8080}
LLNG_PUB_PORT=${LLNG_PUB_PORT:-80}
export APACHE_DOMAIN=$WHITEPAGES_SERVER_NAME
export APACHE_HTTP_PORT=$LLNG_HTTP_PORT
export OPENLDAP_BASE
export OPENLDAP_BIND_DN_PREFIX
export OPENLDAP_DOMAIN
export OPENLDAP_HOST
export PUBLIC_PROTO=${LLNG_PROTO:-'http'}
SSL_INCLUDE=no-ssl
if test -s /var/apache-secret/server.key \
	-a -s /var/apache-secret/server.crt; then
    SSL_INCLUDE=do-ssl
elif test "$PUBLIC_PROTO" = https; then
    SSL_INCLUDE=kindof-ssl
fi

echo "Install LemonLDAP-NG Service Configuration"
ls /usr/share/lemon/etc-lemonldap-ng/ 2>/dev/null | while read conf
    do
	sed -e "s LDAP_PROTO $OPENLDAP_PROTO g" \
	    -e "s LDAP_HOST $OPENLDAP_HOST g" \
	    -e "s HTTP_PORT $LLNG_HTTP_PORT g" \
	    -e "s LOG_LEVEL $APACHE_LOG_LEVEL g" \
	    -e "s LDAP_PORT $OPENLDAP_PORT g" \
	    -e "s|LDAP_SUFFIX|$OPENLDAP_BASE|g" \
	    -e "s LDAP_DOMAIN $OPENLDAP_DOMAIN g" \
	    -e "s|LDAP_CONF_DN_PREFIX|$OPENLDAP_CONF_DN_PREFIX|g" \
	    -e "s|LDAP_BIND_DN_PREFIX|$OPENLDAP_BIND_DN_PREFIX|g" \
	    -e "s|LDAP_BIND_PW|$OPENLDAP_BIND_PW|g" \
	    -e "s|HTTP_PUB_PORT|$LLNG_PUB_PORT|g" \
	    -e "s SSL_TOGGLE_INCLUDE /etc/apache2/$SSL_INCLUDE.conf g" \
	    "/usr/share/lemon/etc-lemonldap-ng/$conf" >"/etc/lemonldap-ng/$conf"
    done
chmod 640 /etc/lemonldap-ng/lemonldap-ng.ini
