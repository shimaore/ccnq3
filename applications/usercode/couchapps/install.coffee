#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
cfg = require 'ccnq3_config'
cfg (config)->

  usercode_uri = config.usercode?.couchdb_uri
  if usercode_uri
    cfg.security usercode_uri, 'usercode', false
    push_script uri, 'main'   # Filter replication from source to user's databases.
    return

  # Create the usercode database.
  usercode_uri = config.install?.usercode?.couchdb_uri ? config.admin.couchdb_uri + '/usercode'
  usercode = pico usercode_uri
  usercode.create ->

    cfg.security usercode_uri, 'usercode', false
    push_script uri, 'main'   # Filter replication from source to user's databases.

    # Save the URI
    config.usercode =
      couchdb_uri: usercode_uri
    cfg.update config
