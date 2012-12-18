#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

ccnq3 = require 'ccnq3'
ccnq3.config (config) ->

  # If the database already exists
  monitor_uri = config.monitor?.couchdb_uri
  if monitor_uri
    ccnq3.db.security monitor_uri, 'monitor', true
    push_script monitor_uri, 'main'
    return

  # Otherwise create the database
  return unless config.install?.monitor? or config.admin?.couchdb_uri?
  monitor_uri = config.install?.monitor?.couchdb_uri ? config.admin.couchdb_uri + '/monitor'
  monitor = pico monitor_uri
  monitor.create ->

    ccnq3.db.security monitor_uri, 'monitor', true
    push_script monitor_uri, 'main'

    # Save the new URI in the configuration
    config.monitor ?= {}
    config.monitor.couchdb_uri = monitor_uri
    ccnq3.config.update config
