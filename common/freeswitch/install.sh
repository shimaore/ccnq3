#!/bin/sh

sudo mv /opt/freeswitch/conf /opt/freeswitch/conf."`date --rfc-3339=seconds`"
sudo cp -r conf /opt/freeswitch/
sudo cp -r lang /opt/freeswitch/conf/
sudo chown -R freeswitch.daemon /opt/freeswitch/conf
