#!/usr/bin/env coffee

couchapp = require 'couchapp'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  # Create the provisioning database.
  provisioning_uri = config.provisioning.couchdb_uri
  push_script provisioning_uri, 'opensips'

  location_uri = config.opensips_proxy.usrloc_uri
  push_script location_uri, 'opensips'
  push_script location_uri, 'location'
