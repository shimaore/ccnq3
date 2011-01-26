#!/bin/bash

daemon -n opensips-http-db -r  -D `dirname "$0"` -- zappa -p 34340 main.coffee