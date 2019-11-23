#!/bin/bash

. /main-init.sh

if test "$LEMON_CUSTOM_THEMES" -a -s $HOME/.ssh/id_rsa; then
    (
	echo "Install LemonLDAP-NG Custom Theme"
	cd /tmp
	GIT_DIR=$(basename `echo "$LEMON_CUSTOM_THEMES" | sed 's|\.git$||'`)
	GIT_REMOTE=`echo $LEMON_CUSTOM_THEMES | sed 's|^.*://\([^/:]*\).*|\1|'`
#	GIT_BRANCH=${GIT_BRANCH:-'master'}
	GIT_SSH_PORT=${GIT_SSH_PORT:-22}
	#ssh-keyscan -p $GIT_SSH_PORT $GIT_REMOTE >$HOME/.ssh/authorized_keys
	cat $HOME/.ssh/id_rsa >$HOME/.ssh/my_id_rsa
	chmod 0600 $HOME/.ssh/my_id_rsa
	if ! GIT_SSH_COMMAND="ssh -i $HOME/.ssh/my_id_rsa \
	    -o UserKnownHostsFile=/dev/null \
	    -o StrictHostKeyChecking=no -p$GIT_SSH_PORT" \
	    git clone "$LEMON_CUSTOM_THEMES"; then
	    echo Failed cloning custom themes >&2
	else
	    cd $GIT_DIR
	    git checkout "$GIT_BRANCH" || \
		echo "Warning: Failed switching branch, using default instead"
	    rm -fr .git
	    find . -type f | while read file
		do
		    if echo "$file" | grep /images/ >/dev/nul; then
			dfile=`echo "$file" | sed 's|^.*/images/||'`
			TARGET=htdocs/static/custom
		    else
			dfile="$file"
			TARGET=templates/custom
		    fi
		    if test -s "$SKINS_ROOT/$TARGET/$dfile"; then
			rm -f "$SKINS_ROOT/$TARGET/$dfile"
		    fi
		    echo "Installing custom theme asset: $dfile"
		    tdir=`dirname "$dfile"`
		    if ! test -d "$SKINS_ROOT/$TARGET/$tdir"; then
			mkdir -p "$SKINS_ROOT/$TARGET/$tdir"
		    fi
		    cp -f "$file" "$SKINS_ROOT/$TARGET/$dfile"
		done
	fi
	rm -fr $HOME/.ssh/my_id_rsa /tmp/$GIT_DIR
    )
fi

echo "Install LemonLDAP-NG Apache Configuration"
for vhost in handler manager portal
do
    ln -vsf /etc/lemonldap-ng/$vhost.conf \
	/etc/apache2/sites-enabled/02-llng-$vhost.conf
done
mkdir -p /etc/lemonldap-ng/mod_fcgid

unset LEMON_CUSTOM_THEMES LLNG_HTTP_PORT LLNG_PROTO APACHE_LOG_LEVEL
. /run-apache.sh
