#!/usr/bin/env coffee

couchapp = require 'couchapp'

# Load Configuration
config = require('ccnq3_config').config

uri = config.users.couchdb_uri

couchapp.createApp require("./users"), uri, (app)-> app.push()
