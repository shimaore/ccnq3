#!/bin/bash

sudo aptitude install -y opensips opensips-dbhttp-module opensips-json-module
sudo adduser `whoami` opensips # allows access to fifo

sudo sed -i -e 's/RUN_OPENSIPS=no/RUN_OPENSIPS=yes/' /etc/default/opensips
echo 'TZ=UTC' | sudo tee -a /etc/default/opensips

sudo ./make.pl default.json conference.json local-vars.json

sudo /etc/init.d/opensips restart
