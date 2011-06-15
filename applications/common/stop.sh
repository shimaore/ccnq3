#!/usr/bin/env bash

daemon -n "ccnq3_replication" -o daemon.debug --stop
daemon -n "ccnq3_send_mail"   -o daemon.debug --stop
