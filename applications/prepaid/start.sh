#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "ccnq3_prepaid"     -D "${CHDIR}/node" -r -o daemon.debug -- coffee start_prepaid.coffee
daemon -n "ccnq3_esl_prepaid" -D "${CHDIR}/node" -r -o daemon.debug -- coffee esl_server.coffee
