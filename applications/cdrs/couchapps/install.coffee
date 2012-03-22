#!/usr/bin/env coffee

# This will create a local "cdrs" database (note the "s" to differentiate from local "cdr" databases).
# This will also allow hosts that have a "cdr_aggregate_uri" to update documents in this database.

cdb = require 'cdb'

cfg = require 'ccnq3_config'
cfg.get (config) ->

  update = (uri) ->
    cdrs = cdb.new uri

    cdrs.security (p) ->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("cdrs_admin") if p.admins.roles.indexOf("cdrs_admin") < 0

      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("cdrs_writer") if p.readers.roles.indexOf("cdrs_writer") < 0
      p.readers.roles.push("cdrs_reader") if p.readers.roles.indexOf("cdrs_reader") < 0
      # Hosts have read-write access so that they can push CDRs.
      p.readers.roles.push("host")        if p.readers.roles.indexOf("host") < 0

  # If the database already exists
  cdrs_uri = config.aggregate?.cdrs_uri
  if cdrs_uri
    update cdrs_uri
    return

  # Otherwise create the database
  cdrs_uri = config.install?.aggregate?.cdrs_uri ? config.admin.couchdb_uri + '/cdrs'
  cdrs = cdb.new cdrs_uri
  cdrs.create ->

    update cdrs_uri

    # Save the new URI in the configuration
    config.aggregate ?= {}
    config.aggregate.cdrs_uri = cdrs_uri
    cfg.update config

