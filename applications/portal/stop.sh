#!/usr/bin/env bash

daemon -n "ccnq3_portal"            -o daemon.debug --stop
daemon -n "ccnq3_mail_password"     -o daemon.debug --stop
