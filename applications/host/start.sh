#!/bin/bash
daemon -n "ccnq3_host"     -o daemon.debug -D "`pwd`" -r -- coffee agents/host.coffee
