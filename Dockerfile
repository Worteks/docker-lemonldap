FROM wsweet/apache:latest

# LemonLDAP-NG image for OpenShift Origin

LABEL io.k8s.description="LemonLDAP::NG offers a full AAA (Authentication Authorization Accounting) protection." \
      io.k8s.display-name="LemonLDAP::NG 2.0.6" \
      io.openshift.expose-services="8080:http" \
      io.openshift.tags="sso,lemon,lemonldap,llng,lemonldapng,lemonldapng2,lemonldapng206" \
      io.openshift.non-scalable="false" \
      help="For more information visit https://github.com/Worteks/docker-lemonldap" \
      maintainer="Clément OUDOT <cleoud@worteks.com>, Paul CURIE <paucur@worteks.com>, Samuel MARTIN MORO <sammar@worteks.com>" \
      version="2.0.6"

ENV SKINS_ROOT=/usr/share/lemonldap-ng/portal
USER root
COPY config/* /
RUN set -ex \
    && echo "# Install LemonLDAP::NG dependencies" \
    && mkdir -p /etc/lemonldap-ng \
    && cp -p /root/original-lemonldap-ng.ini \
	/etc/lemonldap-ng/lemonldap-ng.ini \
    && apt-get -y update \
    && apt-get -y install libglib-perl wget git \
	libnet-ldap-perl libcache-cache-perl libdbi-perl perl-modules \
	libwww-perl libxml-simple-perl libsoap-lite-perl libhtml-template-perl \
	libregexp-assemble-perl libregexp-common-perl libjs-jquery \
	libxml-libxml-perl libcrypt-rijndael-perl libio-string-perl \
	libxml-libxslt-perl libconfig-inifiles-perl libjson-perl \
	libstring-random-perl libemail-date-format-perl libmime-lite-perl \
	libcrypt-openssl-rsa-perl libdigest-hmac-perl libdigest-sha-perl \
	libclone-perl libauthen-sasl-perl libnet-cidr-lite-perl liblasso-perl \
	libcrypt-openssl-x509-perl libauthcas-perl libtest-pod-perl \
	libtest-mockobject-perl libauthen-captcha-perl openssh-client \
	libnet-openid-consumer-perl libnet-openid-server-perl libdbd-pg-perl \
	libunicode-string-perl libconvert-pem-perl libmoose-perl libplack-perl \
    && if test "$DO_UPGRADE"; then \
	apt-get -y upgrade; \
	apt-get -y dist-upgrade; \
    fi \
    && echo "# Install LemonLDAP::NG package" \
    && echo Y | apt-get -y install libapache2-mod-fcgid lemonldap-ng \
    && rm -fr /etc/apache2/sites-available/*apache2.conf \
	/etc/lemonldap-ng/*apache2.conf /etc/lemonldap-ng/*nginx.conf \
	/etc/lemonldap-ng/lemonldap-ng.ini /usr/share/lemon \
    && mv /handler.conf /manager.conf /portal.conf /lemonldap-ng.ini \
	/etc/lemonldap-ng/ \
    && echo "# Backup Original Configuration" \
    && mkdir /usr/share/lemon \
    && mv /etc/lemonldap-ng /usr/share/lemon/etc-lemonldap-ng \
    && mv /var/lib/lemonldap-ng/conf \
	/usr/share/lemon/var-lib-lemonldap-ng-conf \
    && echo "# Configure Apache" \
    && a2dismod mpm_event \
    && a2enmod fcgid mpm_prefork \
    && echo "FcgidIPCDir /etc/lemonldap-ng/mod_fcgid" \
	>>/etc/apache2/mods-available/fcgid.conf \
    && echo "FcgidProcessTableFile /etc/lemonldap-ng/mod_fcgid/fcgid_shm" \
	>>/etc/apache2/mods-available/fcgid.conf \
    && if test "$DEBUG"; then \
	echo "# Install Debugging Tools" \
	&& sed -i 's|LogLevel warn|LogLevel debug|' /etc/apache2/apache2.conf \
	&& apt-get -y install vim ldap-utils; \
    fi \
    && echo "# Install Wsweet theme" \
    && mkdir -p /var/lib/lemonldap-ng/portal/skins \
    && for skin in wsweet custom; \
	do \
	    ( \
		mkdir -p $SKINS_ROOT/templates/$skin \
		    $SKINS_ROOT/htdocs/static/$skin \
		&& cd $SKINS_ROOT/templates/$skin/ \
		&& cp -rp ../bootstrap/* . \
		&& cd ../../htdocs/static/$skin/ \
		&& cp -rp ../bootstrap/* . \
		&& ln -sf $SKINS_ROOT/templates/$skin \
		    /var/lib/lemonldap-ng/portal/skins/; \
	    ); \
	done \
    && rm -f $SKINS_ROOT/tempaltes/wsweet/customheader.tpl \
    && mkdir /.ssh \
    && chmod 0770 /.ssh \
    && chown 1001:root /.ssh \
    && echo "# Remove spurious configuration" \
    && rm -rf /var/lib/apt/lists/* /usr/share/doc /usr/share/man \
	/etc/ssh/ssh_config /tmp/lemonldap-ng-config /theme \
	/etc/apache2/sites-enabled/*default* \
    && for dir in $SKINS_ROOT/templates/custom /etc/lemonldap-ng \
	$SKINS_ROOT/htdocs/static/custom /var/lib/lemonldap-ng/notifications; \
	do \
	    mkdir -p $dir 2>/dev/null \
	    && chown -R 1001:root "$dir" \
	    && chmod -R g=u "$dir"; \
	done \
    && unset HTTP_PROXY HTTPS_PROXY NO_PROXY DO_UPGRADE http_proxy https_proxy

COPY images/* $SKINS_ROOT/htdocs/static/common/apps/
COPY theme/*.tpl $SKINS_ROOT/templates/wsweet/
COPY theme/logo_wsweet.png $SKINS_ROOT/htdocs/static/wsweet/

USER 1001
ENTRYPOINT ["dumb-init","--","/run-lemonldap.sh"]
CMD "/usr/sbin/apache2ctl" "-D" "FOREGROUND"
