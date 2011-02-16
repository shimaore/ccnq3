#!/usr/bin/env bash

SCRIPT_DIR=`dirname "$0"`
if [ "x${SCRIPT_DIR}" == "x." ]; then
  SCRIPT_DIR=`pwd`
fi

daemon -n sotel-video-portal -r -D ${SCRIPT_DIR} -o daemon.debug -- zappa -p 5678 form.zappa.coffee