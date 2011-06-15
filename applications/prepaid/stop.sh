#!/usr/bin/env bash

daemon -n "ccnq3_esl_prepaid" -o daemon.debug --stop
daemon -n "ccnq3_prepaid"     -o daemon.debug --stop
