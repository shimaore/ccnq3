#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
cfg = require 'ccnq3_config'

cfg.get (config) ->
  provisioning_uri = config.provisioning.couchdb_uri
  push_script provisioning_uri, 'freeswitch'
