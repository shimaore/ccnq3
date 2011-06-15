#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "ccnq3_replication" -D "${CHDIR}" -r -o daemon.debug -- coffee agents/replication.coffee
daemon -n "ccnq3_send_mail"   -D "${CHDIR}" -r -o daemon.debug -- coffee agents/send_mail.coffee
