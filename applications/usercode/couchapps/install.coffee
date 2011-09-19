#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
require('ccnq3_config').get (config)->

  # Create the usercode database.
  uri = config.usercode.couchdb_uri
  usercode = cdb.new(uri)
  usercode.create ->

    # Set the security object for the usercode database.
    usercode.security (p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("usercode_admin") if p.admins.roles.indexOf("usercode_admin") < 0
      p.readers ||= {}
      p.readers.roles = []
      p.readers.roles.push("usercode_writer") if p.readers.roles.indexOf("usercode_writer") < 0
      p.readers.roles.push("usercode_reader") if p.readers.roles.indexOf("usercode_reader") < 0

      # (Write access is restricted by the validator.)

    push_script uri, 'main'   # Filter replication from source to user's databases.

  # There is no "usercode" component for the "usercode" database.
