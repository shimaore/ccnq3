#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

ccnq3 = require 'ccnq3'
ccnq3.config (config) ->

  # If the database already exists
  logging_uri = config.logging?.couchdb_uri
  if logging_uri
    ccnq3.db.security logging_uri, 'logging', true
    push_script logging_uri, 'main'
    return

  # Otherwise create the database
  return unless config.install?.logging? or config.admin?.couchdb_uri?
  logging_uri = config.install?.logging?.couchdb_uri ? config.admin.couchdb_uri + '/logging'
  logging = pico logging_uri
  logging.create ->

    ccnq3.db.security logging_uri, 'logging', true
    push_script logging_uri, 'main'

    # Save the new URI in the configuration
    config.logging ?= {}
    config.logging.couchdb_uri = logging_uri
    ccnq3.config.update config
