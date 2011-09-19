#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
require('ccnq3_config').get (config)->

  uri = config.prepaid.couchdb_uri

  cdb.new(uri).create ->

    couchapp.createApp require("./prepaid"), uri, (app)-> app.push()
