#!/usr/bin/env bash

echo "Installing rules into host."
coffee -c host.coffee
couchapp push host.js "${CDB_URI}/provisioning"
rm -f host.js
