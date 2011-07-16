#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

uri = config.provisioning.couchdb_uri

cdb.new(uri).create()

push_script = (script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# push_script 'authorize', -> push_script 'replicate' -> push_script 'global'
push_script process.argv[2]
