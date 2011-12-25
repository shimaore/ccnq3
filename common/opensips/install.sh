#!/bin/bash

# These packages are now part of ccnq-base.
# sudo aptitude install -y opensips opensips-dbhttp-module opensips-json-module
sudo adduser `whoami` opensips # allows access to fifo

sudo sed -i -e 's/RUN_OPENSIPS=no/RUN_OPENSIPS=yes/' /etc/default/opensips
echo 'TZ=UTC' | sudo tee -a /etc/default/opensips > /dev/null

# FIXME make sure that:
#  a) the opensips-http-db server is configured (opensips_proxy field)
#  b) the opensips configuration server is configured (opensips field)
#  b) the usrloc database ("location") is created (and accessible r/w to the user specified in opensips_proxy.usrloc_uri)
#  c) npm install is ran for applications/opensips
#  c) npm run-script couchapps is ran for applications/opensips
#  d) npm stop; npm start is ran for applications/opensips

# done by the opensips agent.
# sudo ./make.coffee default.json conference.json local-vars.json
# However the agent doesn't automatically restart opensips.

sudo /etc/init.d/opensips restart
