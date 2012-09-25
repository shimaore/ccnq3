#!/usr/bin/env coffee

pico = require 'pico'

ccnq3 = require 'ccnq3'
ccnq3.config (config) ->

  # If the database already exists
  logging_uri = config.logging?.couchdb_uri
  if logging_uri
    ccnq3.db.security logging_uri, 'logging', true
    return

  # Otherwise create the database (only on manager host)
  return unless config.install?.logging? or config.admin?.couchdb_uri?
  logging_uri = config.install?.logging?.couchdb_uri ? config.admin.couchdb_uri + '/logging'
  logging = pico logging_uri
  logging.create ->

    ccnq3.db.security logging_uri, 'logging', true

    # Save the new URI in the configuration
    config.logging ?= {}
    config.logging.couchdb_uri = logging_uri
    ccnq3.config.update config
