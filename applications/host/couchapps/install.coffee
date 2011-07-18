#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

uri = config.provisioning.couchdb_uri
cdb.new(uri).create()
couchapp.createApp require('./host'), uri, (app)-> app.push()
