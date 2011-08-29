#!/bin/bash
daemon -n "ccnq3_commands" -o daemon.debug --stop
daemon -n "ccnq3_host"     -o daemon.debug --stop
