#!/usr/bin/env coffee

# This will create a local "cdrs" database (note the "s" to differentiate from local "cdr" databases).
# This will also allow hosts that have a "cdr_aggregate_uri" to update documents in this database.

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

ccnq3 = require 'ccnq3'
ccnq3.config (config) ->

  # If the database already exists
  cdrs_uri = config.aggregate?.cdrs_uri
  if cdrs_uri
    ccnq3.db.security cdrs_uri, 'cdrs', true
    push_script cdrs_uri, 'main'
    push_script cdrs_uri, 'addon'
    return

  # Otherwise create the database
  return unless config.install?.aggregate?.cdrs_uri? or config.admin?.couchdb_uri?
  cdrs_uri = config.install?.aggregate?.cdrs_uri ? config.admin.couchdb_uri + '/cdrs'
  cdrs = pico cdrs_uri
  cdrs.create ->

    ccnq3.db.security cdrs_uri, 'cdrs', true
    push_script cdrs_uri, 'main'

    # Save the new URI in the configuration
    config.aggregate ?= {}
    config.aggregate.cdrs_uri = cdrs_uri
    ccnq3.config.update config
