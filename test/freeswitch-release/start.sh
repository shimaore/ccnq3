#!/bin/bash
DIR="`pwd`"
OK=true
for PACKAGE in freeswitch freeswitch-mod-hash freeswitch-mod-commands freeswitch-mod-dptools freeswitch-mod-loopback freeswitch-mod-console freeswitch-mod-dialplan-xml freeswitch-mod-sofia ; do
  dpkg -l "${PACKAGE}" > /dev/null 2>&1 || { echo "Missing $PACKAGE"; OK=false; }
done
if [ "$OK" == "false" ]; then exit 1; fi
mkdir -p "$DIR/var"
mkdir -p "/dev/shm/freeswitch"
ulimit -s 240

killall freeswitch
killall sipp

# UAC
sipp -bg \
  -d 1500 -nostdin -timeout 40 \
  -l 1 -m 1 -r 1 \
  -log_file uac.log -error_file uac-error.log -message_file uac-message.log -trace_msg uac-trace.log \
  -trace_msg -trace_screen -trace_err -trace_logs \
  -i 127.0.0.1 -mi 127.0.0.1 \
  -bind_local -default_behaviors none -nd -fd 1 \
  -sf uac-with-reinvite.xml -p 15060 \
  -s 163578273827 -set from_user 12021237654 127.0.0.1:5060

# UAS
sipp -bg \
  -d 1500 -nostdin -timeout 40 \
  -l 1 -m 1 -r 1 \
  -log_file uas.log -error_file uas-error.log -message_file uas-message.log -trace_msg uas-trace.log \
  -trace_msg -trace_screen -trace_err -trace_logs \
  -i 127.0.0.1 -mi 127.0.0.1 \
  -bind_local -default_behaviors none -nd -fd 1 \
  -sf uas-with-reinvite.xml -p 15062 \
  127.0.0.1:5060

freeswitch -c -nonat -nonatmap -nort \
    -mod /usr/lib/freeswitch/mod \
    -base "$DIR" -conf "$DIR" -log "$DIR/var" -run "$DIR/var" -db "$DIR/var" -scripts "$DIR/conf" -temp "$DIR/var"
