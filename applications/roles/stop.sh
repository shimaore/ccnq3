#!/usr/bin/env bash

daemon -n "ccnq3_admin"             -o daemon.debug --stop
daemon -n "ccnq3_track_users"       -o daemon.debug --stop
