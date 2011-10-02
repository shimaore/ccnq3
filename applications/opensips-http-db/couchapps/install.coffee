#!/usr/bin/env coffee

couchapp = require 'couchapp'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  # Create the provisioning database.
  provisioning_uri = config.provisioning.couchdb_uri

  push_script provisioning_uri, 'opensips'

