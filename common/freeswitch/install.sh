#!/bin/sh

# Install
sudo aptitude -y install freeswitch freeswitch-lua
sudo adduser `whoami` daemon # allows access to configuration directory

# FIXME -- this should be replaced with some kind of in-memory system.
grep '/opt/freeswitch/db' /etc/fstab || sudo tee -a /etc/fstab >/dev/null <<'CONF'
fsdbfs /opt/freeswitch/db tmpfs defaults 0 0
CONF
sudo mount /opt/freeswitch/db

# Startup parameters
sudo sed -i -e 's/^FREESWITCH_ENABLED="false"/FREESWITCH_ENABLED="true"/' /etc/default/freeswitch
sudo sed -i -e 's/^FREESWITCH_PARAMS="-nc"/FREESWITCH_PARAMS="-nc -nonat"/' /etc/default/freeswitch

# Default configuration
sudo mv /opt/freeswitch/conf /opt/freeswitch/conf."`date --rfc-3339=seconds`"
sudo cp -r conf /opt/freeswitch/
sudo cp -r lang /opt/freeswitch/conf/
sudo chown -R freeswitch.daemon /opt/freeswitch/conf

# Apply
sudo /etc/init.d/freeswitch restart
