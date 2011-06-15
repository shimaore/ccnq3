#!/usr/bin/env bash

echo "Installing prepaid couchapp."
coffee -c prepaid.coffee
couchapp push prepaid.js "${CDB_URI}/prepaid"
rm -f prepaid.js
