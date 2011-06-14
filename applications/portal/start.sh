#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "ccnq3_mail_confirmation" -D "${CHDIR}" -r -o daemon.debug -- coffee agents/mail_confirmation.coffee
daemon -n "ccnq3_mail_password"     -D "${CHDIR}" -r -o daemon.debug -- coffee agents/mail_password.coffee
daemon -n "ccnq3_portal"            -D "${CHDIR}" -r -o daemon.debug -- coffee start_portal.coffee

