#!/bin/bash

SCRIPT_DIR=`dirname "$0"`
if [ "x${SCRIPT_DIR}" == "x." ]; then
  SCRIPT_DIR=`pwd`
fi

daemon -n opensips-http-db -r -D ${SCRIPT_DIR} -o daemon.debug -- zappa -p 34340 main.coffee