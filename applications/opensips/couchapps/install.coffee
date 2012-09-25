#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3').config (config)->

  # These only get installed on host running OpenSIPS.

  # Install the views so that opensips-proxy might work.
  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.create ->
    push_script provisioning_uri, 'opensips'

  # Create this database (local to the host, normally)
  location_uri = config.opensips_proxy?.usrloc_uri ? 'http://127.0.0.1:5984/location'
  location = pico location_uri
  location.create ->
    push_script location_uri, 'opensips' # for CommonJS
    push_script location_uri, 'location'
