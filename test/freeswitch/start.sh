#!/bin/bash
DIR="`pwd`"
OK=true
for PACKAGE in freeswitch freeswitch-mod-event-socket freeswitch-mod-hash freeswitch-mod-commands freeswitch-mod-dptools freeswitch-mod-loopback freeswitch-mod-console freeswitch-mod-logfile freeswitch-mod-dialplan-xml freeswitch-mod-sofia freeswitch-mod-sndfile freeswitch-sounds-en-us-callie-8000 freeswitch-sounds-fr-fr-sibylle-8000; do
  dpkg -l "${PACKAGE}" > /dev/null 2>&1 || { echo "Missing $PACKAGE"; OK=false; }
done
if [ "$OK" == "false" ]; then exit 1; fi
mkdir -p "$DIR/var"
mkdir -p "/dev/shm/freeswitch"
ulimit -s 240
freeswitch -c -nonat -nonatmap -nort \
    -mod /usr/lib/freeswitch/mod \
    -base "$DIR" -conf "$DIR" -log "$DIR/var" -run "$DIR/var" -db "$DIR/var" -scripts "$DIR/conf" -temp "$DIR/var"
# coffee server.coffee
