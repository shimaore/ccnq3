#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

# Installation
uri = config.users.couchdb_uri
couchapp.createApp require("./users"), uri, (app)-> app.push()
