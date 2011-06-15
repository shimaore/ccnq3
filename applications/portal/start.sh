#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "ccnq3_mail_confirmation" -D "${CHDIR}/agents" -r -o daemon.debug -- coffee mail_confirmation.coffee
daemon -n "ccnq3_mail_password"     -D "${CHDIR}/agents" -r -o daemon.debug -- coffee mail_password.coffee
daemon -n "ccnq3_portal"            -D "${CHDIR}/node"   -r -o daemon.debug -- coffee start_portal.coffee
