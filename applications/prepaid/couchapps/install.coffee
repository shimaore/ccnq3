#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
require('ccnq3_config').get (config)->

  prepaid_uri = config.prepaid.couchdb_uri

  # FIXME: the prepaid couchdb_uri doesn't have the proper rights.
  cdb.new(prepaid_uri).create ->

    push_script prepaid_uri, "prepaid"
