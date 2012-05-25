#!/usr/bin/env coffee

pico = require 'pico'

cfg = require 'ccnq3_config'
cfg.get (config) ->

  update = (uri) ->
    locations = pico uri

    locations.get '_security', json:true, (e,r,p) ->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("locations_admin") if p.admins.roles.indexOf("locations_admin") < 0

      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("locations_writer") if p.readers.roles.indexOf("locations_writer") < 0
      p.readers.roles.push("locations_reader") if p.readers.roles.indexOf("locations_reader") < 0
      # Hosts have read-write access so that they can push location updates.
      p.readers.roles.push("host")             if p.readers.roles.indexOf("host") < 0

      locations.put '_security', json:p

  # If the database already exists
  locations_uri = config.aggregate?.locations_uri
  if locations_uri
    update locations_uri
    return

  # Otherwise create the database
  locations_uri = config.install?.aggregate?.locations_uri ? config.admin.couchdb_uri + '/locations'
  locations = pico locations_uri
  locations.put ->

    update locations_uri

    # Save the new URI in the configuration
    config.aggregate ?= {}
    config.aggregate.locations_uri = locations_uri
    cfg.update config
