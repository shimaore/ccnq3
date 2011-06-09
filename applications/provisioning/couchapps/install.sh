#!/usr/bin/env bash

echo "Creating CouchDB provisioning."
curl -X PUT "${CDB_URI}/provisioning"

echo "Installing rules into databases."
for script in authorize replicate global; do
  coffee -c $script.js
  couchapp push script.js "${CDB_URI}/provisioning"
  rm $script.js
done

