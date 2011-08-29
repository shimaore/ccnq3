#!/bin/bash
daemon -n "ccnq3_commands" -o daemon.debug -D "`pwd`" -r -- coffee agents/commands.coffee
