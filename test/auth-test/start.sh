#!/bin/bash
killall sipp

# /usr/sbin/opensips -D -E -f opensips.cfg

# UAC
sipp \
  -d 1500 -nostdin -timeout 40 \
  -l 1 -m 1 -r 1 \
  -log_file uac.log -error_file uac-error.log -message_file uac-message.log -trace_msg uac-trace.log \
  -trace_msg -trace_screen -trace_err -trace_logs \
  -bind_local -default_behaviors none -nd -fd 1 \
  -sf uac.xml -p 15060 \
  -i 127.0.0.1 -mi 127.0.0.1 \
  -s 163578273827 -set from_user 12021237654 127.0.0.1:5067
#  -i 192.168.5.229 -mi 192.168.5.229 \
#  -s 163578273827 -set from_user 12021237654 termination2.sotelips.net
