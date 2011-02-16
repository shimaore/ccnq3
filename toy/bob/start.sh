#!/bin/bash

SCRIPT_DIR=`dirname "$0"`
daemon -n sotel-video-portal -r -D ${SCRIPT_DIR} -o daemon.debug -- zappa -p 5678 form.zappa.coffee