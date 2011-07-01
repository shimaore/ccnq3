#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "sotel_portal"   -D "${CHDIR}/node"   -r -o daemon.debug -- coffee start_portal.coffee
