#!/usr/bin/env bash

CHDIR=`pwd`
daemon -n "ccnq3_host" -D "${CHDIR}" -r -o daemon.debug -- coffee agents/host.coffee
