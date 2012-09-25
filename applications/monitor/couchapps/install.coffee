#!/usr/bin/env coffee

pico = require 'pico'

cfg = require 'ccnq3_config'
cfg (config) ->

  # If the database already exists
  monitor_uri = config.monitor?.couchdb_uri
  if monitor_uri
    cfg.security monitor_uri, 'monitor', true
    return

  # Otherwise create the database (only on manager host)
  return unless config.install?.monitor? or config.admin?.couchdb_uri?
  monitor_uri = config.install?.monitor?.couchdb_uri ? config.admin.couchdb_uri + '/monitor'
  monitor = pico monitor_uri
  monitor.create ->

    cfg.security monitor_uri, 'monitor', true

    # Save the new URI in the configuration
    config.monitor =
      couchdb_uri: monitor_uri
    cfg.update config
