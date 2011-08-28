#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

uri = config.provisioning.couchdb_uri
cdb.new(uri).create()

# Install the couchapp scripts.
push_script = (script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# These couchapps are available to provisioning_admin (and _admin) users.
push_script 'host'
