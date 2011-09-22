#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  # Create the partner database.
  uri = config.sotel_portal.couchdb_uri
  partner = cdb.new(uri)
  partner.create ->

    # Set the security object for the provisioning database.
    partner.security (p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("partner_admin") if p.admins.roles.indexOf("partner_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("partner_writer") if p.readers.roles.indexOf("partner_writer") < 0
      p.readers.roles.push("partner_reader") if p.readers.roles.indexOf("partner_reader") < 0

    # These couchapps are available to provisioning_admin (and _admin) users.
    push_script uri, 'main'   # Filter replication from source to user's databases.

  # Also push the user-database application into the usercode repository
  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'
