#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

cfg = require 'ccnq3_config'
cfg.get (config)->

  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'

  # Update ACLs and code
  update = (uri) ->
    provisioning = pico uri

    # Set the security object for the provisioning database.
    provisioning.get '_security', json:true, (e,r,p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("provisioning_admin") if p.admins.roles.indexOf("provisioning_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("provisioning_writer") if p.readers.roles.indexOf("provisioning_writer") < 0
      p.readers.roles.push("provisioning_reader") if p.readers.roles.indexOf("provisioning_reader") < 0
      # Hosts have direct (read-only) access to the provisioning database (for replication / host-agent purposes).
      p.readers.roles.push("host")                if p.readers.roles.indexOf("host") < 0

      provisioning.put '_security', json:p

    # These couchapps are available to provisioning_admin (and _admin) users.
    push_script uri, 'main'   # Filter replication from source to user's databases.

  # If the database already exists
  provisioning_uri = config.provisioning?.couchdb_uri
  if provisioning_uri
    update provisioning_uri
    return

  # Otherwise create the database
  provisioning_uri = config.install?.provisioning?.couchdb_uri ? config.admin.couchdb_uri + '/provisioning'
  provisioning = pico provisioning_uri
  provisioning.put ->

    update provisioning_uri

    # Save the new URI in the configuration
    config.provisioning =
      couchdb_uri: provisioning_uri
    cfg.update config
