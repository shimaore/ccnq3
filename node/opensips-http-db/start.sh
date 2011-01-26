#!/bin/bash

daemon -n opensips-http-db -r -- zappa -p 34340 -w main.coffee