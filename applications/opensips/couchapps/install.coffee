#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  # These only get installed on host running OpenSIPS.

  # Install the views so that opensips-proxy might work.
  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = cdb.new provisioning_uri
  provisioning.create ->
    push_script provisioning_uri, 'opensips'

  # Create this database (local to the host, normally)
  location_uri = config.opensips_proxy.usrloc_uri ? 'http://127.0.0.1:5984/location'
  location = cdb.new(location_uri)
  location.create ->
    push_script location_uri, 'opensips' # for CommonJS
    push_script location_uri, 'location'
