#!/bin/bash

SCRIPT_DIR=`dirname "$0"`
daemon -n opensips-http-db -r -D ${SCRIPT_DIR} -o daemon.debug -- zappa -p 34340 main.coffee