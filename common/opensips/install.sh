#!/bin/bash

sudo sed -i -e 's/RUN_OPENSIPS=no/RUN_OPENSIPS=yes/' /etc/default/opensips

sudo ./make.pl default.json conference.json local-vars.json

sudo /etc/init.d/opensips restart
