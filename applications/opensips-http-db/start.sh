#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "ccnq3_opensips_http_db"   -D "${CHDIR}/node" -r -o daemon.debug -- coffee start_proxy.coffee
