#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

ccnq3 = require 'ccnq3'
ccnq3.config (config) ->

  # If the database already exists
  locations_uri = config.aggregate?.locations_uri
  if locations_uri
    ccnq3.db.security locations_uri, 'locations', true
    push_script locations_uri, 'main'
    return

  # Otherwise create the database
  locations_uri = config.install?.aggregate?.locations_uri ? config.admin.couchdb_uri + '/locations'
  locations = pico locations_uri
  locations.create ->

    ccnq3.db.security locations_uri, 'locations', true
    push_script locations_uri, 'main'

    # Save the new URI in the configuration
    config.aggregate ?= {}
    config.aggregate.locations_uri = locations_uri
    ccnq3.config.update config
