#!/bin/sh
# Must be ran as root
/sbin/iptables -t nat -A PREROUTING -p udp -m udp --dport 53 -j REDIRECT --to-ports 53053
