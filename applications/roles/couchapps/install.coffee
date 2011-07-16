#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

# Installation
uri = config.users.couchdb_uri
couchapp.createApp require("./users"), uri, (app)-> app.push()

uri = config.databases.couchdb_uri
cdb.new(uri).create()
couchapp.createApp require("./databases"), uri, (app)-> app.push()
