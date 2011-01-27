#!/bin/bash

# install (dispatcher|(relay|both) [dispatcher1 [dispatcher2 [...]]])

ACTION=$1
shift

if [ "x$ACTION" == "xdispatcher" ]; then

  sudo aptitude -y install mediaproxy-dispatcher

  sudo mkdir -p /etc/mediaproxy/dispatcher
  sudo cp ./dispatcher/config.ini   /etc/mediaproxy/
  sudo cp ./dispatcher/dispatcher.* /etc/mediaproxy/dispatcher

  sudo /etc/init.d/mediaproxy-dispatcher restart

fi

if [ "x$ACTION" == "xrelay" ]; then

  sudo aptitude -y install mediaproxy-relay

  sudo mkdir -p /etc/mediaproxy/relay
  sed -e "s/\${dispatcher_names}/$*/" ./relay/config.ini | \
    sudo tee /etc/mediaproxy/config.ini >/dev/null
  sudo cp ./relay/relay.* /etc/mediaproxy/relay

  sudo /etc/init.d/mediaproxy-relay restart

fi

if [ "x$ACTION" == "xboth" ]; then

  sudo aptitude -y install mediaproxy-dispatcher mediaproxy-relay

  sudo mkdir -p /etc/mediaproxy/dispatcher
  sudo mkdir -p /etc/mediaproxy/relay
  cat ./*/config.ini | \
    sed -e "s/\${dispatcher_names}/$*/" | \
    sudo tee /etc/mediaproxy/config.ini >/dev/null
  sudo cp ./dispatcher/dispatcher.* /etc/mediaproxy/dispatcher
  sudo cp ./relay/relay.*           /etc/mediaproxy/relay

  sudo /etc/init.d/mediaproxy-dispatcher restart
  sudo /etc/init.d/mediaproxy-relay restart

fi

