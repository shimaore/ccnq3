#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  # Create the provisioning database.
  provisioning_uri = config.provisioning.couchdb_uri
  provisioning = cdb.new(provisioning_uri)
  provisioning.create ->

    # Set the security object for the provisioning database.
    provisioning.security (p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("provisioning_admin") if p.admins.roles.indexOf("provisioning_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("provisioning_writer") if p.readers.roles.indexOf("provisioning_writer") < 0
      p.readers.roles.push("provisioning_reader") if p.readers.roles.indexOf("provisioning_reader") < 0
      # Hosts have direct (read-only) access to the provisioning database (for replication / host-agent purposes).
      p.readers.roles.push("host")                if p.readers.roles.indexOf("host") < 0

    # These couchapps are available to provisioning_admin (and _admin) users.
    push_script provisioning_uri, 'main'   # Filter replication from source to user's databases.

  # Also push the user-database application into the usercode repository
  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'
