#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
cfg = require 'ccnq3_config'

# ==== Provisioning ====
cfg.get (config) ->
  provisioning_uri = config.provisioning.couchdb_uri
  cdb.new(provisioning_uri).create ->

    # These couchapps are available to provisioning_admin (and _admin) users.
    push_script provisioning_uri, 'main'
