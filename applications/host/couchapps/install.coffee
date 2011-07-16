#!/usr/bin/env coffee

couchapp = require 'couchapp'

# Load Configuration
config = require('ccnq3_config').config

uri = config.provisioning.couchdb_uri

couchapp.createApp require('./host'), uri, (app)-> app.push()
