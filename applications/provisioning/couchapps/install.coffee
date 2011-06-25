#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
fs = require('fs')
config_location = process.env.npm_package_config_bootstrap_file
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

uri = "#{config.couchdb_uri}/provisioning"

cdb.new(uri).create()

push_script = (script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

push_script 'authorize', -> push_script 'replicate' -> push_script 'global'
