#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
ccnq3 = require 'ccnq3'
ccnq3.config (config)->

  usercode_uri = config.usercode?.couchdb_uri
  if usercode_uri
    ccnq3.db.security usercode_uri, 'usercode', false
    push_script usercode_uri, 'main'   # Filter replication from source to user's databases.
    return

  # Create the usercode database.
  usercode_uri = config.install?.usercode?.couchdb_uri ? config.admin.couchdb_uri + '/usercode'
  usercode = pico usercode_uri
  usercode.create ->

    ccnq3.db.security usercode_uri, 'usercode', false
    push_script usercode_uri, 'main'   # Filter replication from source to user's databases.

    # Save the URI
    config.usercode =
      couchdb_uri: usercode_uri
    ccnq3.config.update config
