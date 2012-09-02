#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
cfg = require 'ccnq3_config'
cfg (config)->

  update = (uri) ->
    db = pico uri

    # Set the security object for the usercode database.
    db.request.get '_security', json:true, (e,r,p) ->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("usercode_admin") if p.admins.roles.indexOf("usercode_admin") < 0
      p.readers ||= {}
      p.readers.roles = []
      p.readers.roles.push("usercode_writer") if p.readers.roles.indexOf("usercode_writer") < 0
      p.readers.roles.push("usercode_reader") if p.readers.roles.indexOf("usercode_reader") < 0

      # (Write access is restricted by the validator.)

      db.request.put '_security', json:p

    push_script uri, 'main'   # Filter replication from source to user's databases.

  usercode_uri = config.usercode?.couchdb_uri
  if usercode_uri
    update usercode_uri
    return

  # Create the usercode database.
  usercode_uri = config.install?.usercode?.couchdb_uri ? config.admin.couchdb_uri + '/usercode'
  usercode = pico usercode_uri
  usercode.create ->

    update usercode_uri

    # Save the URI
    config.usercode =
      couchdb_uri: usercode_uri
    cfg.update config
