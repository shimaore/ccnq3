#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "ccnq3_track_users"     -D "${CHDIR}/agents" -r -o daemon.debug -- coffee track_users.coffee
daemon -n "ccnq3_admin"           -D "${CHDIR}/node"   -r -o daemon.debug -- coffee start_admin.coffee
