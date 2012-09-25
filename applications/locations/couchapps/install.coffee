#!/usr/bin/env coffee

pico = require 'pico'

cfg = require 'ccnq3_config'
cfg (config) ->

  # If the database already exists
  locations_uri = config.aggregate?.locations_uri
  if locations_uri
    cfg.security locations_uri, 'locations', true
    return

  # Otherwise create the database
  locations_uri = config.install?.aggregate?.locations_uri ? config.admin.couchdb_uri + '/locations'
  locations = pico locations_uri
  locations.create ->

    cfg.security locations_uri, 'locations', true

    # Save the new URI in the configuration
    config.aggregate ?= {}
    config.aggregate.locations_uri = locations_uri
    cfg.update config
