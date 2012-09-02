#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

cfg = require 'ccnq3_config'
cfg (config)->

  # Update ACLs and code
  update = (uri) ->
    db = pico uri

    # Set the security object for the monitor database.
    db.request.get '_security', json:true, (e,r,p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("monitor_admin") if p.admins.roles.indexOf("monitor_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("monitor_writer") if p.readers.roles.indexOf("monitor_writer") < 0
      p.readers.roles.push("monitor_reader") if p.readers.roles.indexOf("monitor_reader") < 0
      # Hosts have direct access to the monitor database
      p.readers.roles.push("host")                if p.readers.roles.indexOf("host") < 0

      db.request.put '_security', json:p

    # These couchapps are available to monitor_admin (and _admin) users.
    push_script uri, 'main'   # Filter replication from source to user's databases.

  # If the database already exists
  monitor_uri = config.monitor?.couchdb_uri
  if monitor_uri
    update monitor_uri
    return

  # Otherwise create the database
  return unless config.install?.monitor? or config.admin?.couchdb_uri?
  monitor_uri = config.install?.monitor?.couchdb_uri ? config.admin.couchdb_uri + '/monitor'
  monitor = pico monitor_uri
  monitor.create ->

    update monitor_uri

    # Save the new URI in the configuration
    config.monitor =
      couchdb_uri: monitor_uri
    cfg.update config
