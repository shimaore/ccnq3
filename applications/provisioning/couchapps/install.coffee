#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
config = require('ccnq3_config').config

# Create the provisioning database.
uri = config.provisioning.couchdb_uri
provisioning = cdb.new(uri)
provisioning.create ->

  # Set the security object for the provisioning database.
  provisioning.security (p)->
    p.admins ||= {}
    p.admins.roles ||= []
    push p.admins.roles,  "provisioning_admin"  if p.admins?.roles.indexOf("provisioning_admin") < 0
    p.readers ||= {}
    p.readers.roles ||= []
    push p.readers.roles, "provisioning_writer" if p.readers?.roles.indexOf("provisioning_writer") < 0
    push p.readers.roles, "provisioning_reader" if p.readers?.roles.indexOf("provisioning_reader") < 0
    # Hosts have direct (read-only) access to the provisioning database (for replication / host-agent purposes).
    push p.readers.roles, "host"                if p.readers?.roles.indexOf("host") < 0

  # These couchapps are available to provisioning_admin (and _admin) users.
  push_script uri, 'replicate'   # Filter replication from source to user's databases.
