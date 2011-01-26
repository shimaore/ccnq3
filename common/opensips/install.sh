#!/bin/bash

sudo sed -i -e 's/RUN_OPENSIPS=no/RUN_OPENSIPS=yes/' /etc/default/opensips

./make.pl conference.json local-vars.json
sudo mv /tmp/opensips.cfg /etc/opensips/

sudo /etc/init.d/opensips restart
