#!/bin/bash

# install (dispatcher|(relay|both) [dispatcher1 [dispatcher2 [...]]])

ACTION=$1
shift

function do_sysctl {
  sudo sed -i -e 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf
  egrep -q '^net.ipv4.ip_forward=1$' /etc/sysctl.conf || exit

  sudo sed -i -e 's/#net.ipv6.conf.all.forwarding=1/net.ipv6.conf.all.forwarding=1/' /etc/sysctl.conf
  egrep -q '^net.ipv6.conf.all.forwarding=1$' /etc/sysctl.conf || exit
  # Maybe
  #  net.ipv6.conf.default.forwarding=1
  # also?

  sudo sysctl -p /etc/sysctl.conf
}

if [ "x$ACTION" == "xdispatcher" ]; then

  sudo aptitude -y install mediaproxy-dispatcher

  sudo mkdir -p /etc/mediaproxy/tls
  sudo cp ./dispatcher/config.ini   /etc/mediaproxy/
  sudo cp ./dispatcher/dispatcher.* /etc/mediaproxy/tls

  sudo /etc/init.d/mediaproxy-dispatcher restart

fi

if [ "x$ACTION" == "xrelay" ]; then

  sudo aptitude -y install mediaproxy-relay

  sudo mkdir -p /etc/mediaproxy/tls
  sed -e "s/\${dispatcher_names}/$*/" ./relay/config.ini | \
    sudo tee /etc/mediaproxy/config.ini >/dev/null
  sudo cp ./relay/relay.* /etc/mediaproxy/tls

  do_sysctl
  sudo /etc/init.d/mediaproxy-relay restart

fi

if [ "x$ACTION" == "xboth" ]; then

  sudo aptitude -y install mediaproxy-dispatcher mediaproxy-relay

  sudo mkdir -p /etc/mediaproxy/tls
  cat ./*/config.ini | \
    sed -e "s/\${dispatcher_names}/$*/" | \
    sudo tee /etc/mediaproxy/config.ini >/dev/null
  sudo cp ./dispatcher/dispatcher.* /etc/mediaproxy/tls
  sudo cp ./relay/relay.*           /etc/mediaproxy/tls

  do_sysctl
  sudo /etc/init.d/mediaproxy-dispatcher restart
  sudo /etc/init.d/mediaproxy-relay restart

fi

