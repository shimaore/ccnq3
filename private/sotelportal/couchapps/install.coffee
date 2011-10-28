#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  # Create the sotel_portal database.
  uri = config.sotel_portal.couchdb_uri
  sotel_portal = cdb.new(uri)
  sotel_portal.create ->

    # Set the security object for the provisioning database.
    sotel_portal.security (p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("sotel_portal_admin") if p.admins.roles.indexOf("sotel_portal_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("sotel_portal_writer") if p.readers.roles.indexOf("sotel_portal_writer") < 0
      p.readers.roles.push("sotel_portal_reader") if p.readers.roles.indexOf("sotel_portal_reader") < 0

    # These couchapps are available to provisioning_admin (and _admin) users.
    push_script uri, 'main'   # Filter replication from source to user's databases.

  # Also push the user-database application into the usercode repository
  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'
  push_script usercode_uri, 'portal'
