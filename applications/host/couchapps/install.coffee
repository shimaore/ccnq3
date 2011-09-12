#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
config = require('ccnq3_config').config

# ==== Provisioning ====
uri = config.provisioning.couchdb_uri
cdb.new(uri).create ->

  # These couchapps are available to provisioning_admin (and _admin) users.
  push_script uri, 'host'
