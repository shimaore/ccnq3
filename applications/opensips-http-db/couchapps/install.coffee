#!/usr/bin/env coffee

couchapp = require 'couchapp'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  provisioning_uri = config.provisioning.couchdb_uri
  push_script provisioning_uri, 'opensips'

  # FIXME Create this database at some point (but it'll probably be local to the target)
  location_uri = config.opensips_proxy.usrloc_uri
  push_script location_uri, 'opensips'
  push_script location_uri, 'location'
