#!/usr/bin/env bash

echo "Installing rules into _users."
coffee -c users.coffee
couchapp push users.js "${CDB_URI}/_users"
rm users.coffee

echo "Creating CouchDB databases."
curl -X PUT "${CDB_URI}/databases"

echo "Installing rules into databases."
coffee -c databases.js
couchapp push databases.js "${CDB_URI}/databases"
rm databases.js

