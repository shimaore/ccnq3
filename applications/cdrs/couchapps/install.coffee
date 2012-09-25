#!/usr/bin/env coffee

# This will create a local "cdrs" database (note the "s" to differentiate from local "cdr" databases).
# This will also allow hosts that have a "cdr_aggregate_uri" to update documents in this database.

pico = require 'pico'

cfg = require 'ccnq3_config'
cfg (config) ->

  # If the database already exists
  cdrs_uri = config.aggregate?.cdrs_uri
  if cdrs_uri
    cfg.security cdrs_uri, 'cdrs', true
    return

  # Otherwise create the database
  cdrs_uri = config.install?.aggregate?.cdrs_uri ? config.admin.couchdb_uri + '/cdrs'
  cdrs = pico cdrs_uri
  cdrs.create ->

    cfg.security cdrs_uri, 'cdrs', true

    # Save the new URI in the configuration
    config.aggregate ?= {}
    config.aggregate.cdrs_uri = cdrs_uri
    cfg.update config
