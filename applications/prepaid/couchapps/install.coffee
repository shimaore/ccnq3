#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
fs = require('fs')
config_location = process.env.npm_package_config_bootstrap_file
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

uri = "#{config.couchdb_uri}/prepaid"

cdb.new(uri).create()

couchapp.createApp require("./prepaid"), uri, (app)-> app.push()
