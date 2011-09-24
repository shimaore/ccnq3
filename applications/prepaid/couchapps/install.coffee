#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
require('ccnq3_config').get (config)->

  prepaid_uri = config.prepaid.couchdb_uri

  cdb.new(prepaid_uri).create ->

    couchapp.createApp require("./prepaid"), prepaid_uri, (app)-> app.push()
