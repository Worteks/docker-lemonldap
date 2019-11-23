#!/bin/sh

. /main-init.sh

do_cleanup()
{
    if test -x /usr/share/lemonldap-ng/bin/purgeCentralCache; then
	/usr/share/lemonldap-ng/bin/purgeCentralCache -d
    fi
    if test -x /usr/share/lemonldap-ng/bin/purgeLocalCache; then
	/usr/share/lemonldap-ng/bin/purgeLocalCache -d
    fi
}

unset LEMON_CUSTOM_THEMES LLNG_HTTP_PORT LLNG_PROTO APACHE_LOG_LEVEL \
    APACHE_DOMAIN APACHE_HTTP_PORT PUBLIC_PROTO SSL_INCLUDE OPENLDAP_PROTO \
    OPENLDAP_BIND_DN_PREFIX OPENLDAP_BIND_PW OPENLDAP_CONF_DN_PREFIX \
    OPENLDAP_BASE OPENLDAP_PORT
if test "$CLEANUP_PERIOD"; then
    case "$CLEANUP_PERIOD" in
	7day|7days|week|weekly)	SLEEP=604800		;;
	1day|day|daily)		SLEEP=86400		;;
	hour|hourly)		SLEEP=3600		;;
	*)      		SLEEP="$CLEANUP_PERIOD"	;;
    esac
    if ! test "$SLEEP" -gt 110; then
	echo "invalid interval '$SLEEP' - forcing to daily cleanups" >&2
	SLEEP=86400
    fi
    echo "Cleanup interval is $SLEEP seconds ($CLEANUP_PERIOD)"
    while :
    do
	starttime=$(date +%s)
	if ! do_cleanup; then
	    echo "WARNING: cleanup failed!" >&2
	fi
	endtime=$(date +%s)
	sleeptime=$(expr $SLEEP + $starttime - $endtime)
	if test "$sleeptime" -lt 0; then
	    SLEEP=$(expr $SLEEP + $sleeptime + 120)
	    sleeptime=$SLEEP
	    echo "missed last cleanup, as current job took to long"
	    echo "raising cleanup interval to $SLEEP seconds"
	fi >&2
	echo "INFO: sleeping for $sleeptime seconds until next job"
	sleep $sleeptime
    done
    echo "CRITICAL: main loop interrupted, now exiting" >&2
    exit 1
else
    do_cleanup
fi

exit 0
