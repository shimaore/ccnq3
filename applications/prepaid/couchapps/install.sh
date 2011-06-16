#!/usr/bin/env bash

echo "Creating CouchDB prepaid."
curl -X PUT "${CDB_URI}/prepaid"

echo "Installing prepaid couchapp."
coffee -c prepaid.coffee
couchapp push prepaid.js "${CDB_URI}/prepaid"
rm -f prepaid.js
