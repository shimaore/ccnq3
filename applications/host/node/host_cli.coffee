#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Create a username for the new host's main process so that it can bootstrap its own installation.
host = require './host.coffee'

cdb = require 'cdb'

# Load Configuration
ccnq3_config = require 'ccnq3_config'
ccnq3_config.get (config) ->

  hostname = config.host

  if config.admin?.system
    # Manager host

    # Install the local (bootstrap/master) host in the database.
    users = cdb.new config.users.couchdb_uri

    host.create_user users, hostname, (password) ->

      provisioning_uri = config.provisioning.couchdb_uri
      provisioning = cdb.new provisioning_uri

      host.update_config provisioning_uri, provisioning, password, config, (config) ->

        ccnq3_config.update config

  else
    # Non-manager host

    # provisioning.couchdb_uri MUST be "http://127.0.0.1:5984/provisioning"
    expected = "http://127.0.0.1:5984/provisioning"
    source_uri = config.provisioning.host_couchdb_uri
    target_uri = config.provisioning.local_couchdb_uri

    if target_uri isnt expected
      throw "provisioning.local_couchdb_uri should be #{expected}"
    if not source_uri
      throw "provisioning.host_couchdb_uri is required"

    replicator = "http://127.0.0.1:5984/_replicator"
    replicant =
      _id:    'ccnq3_provisioning'
      source: source_uri
      target: 'provisioning' # local target
      create_target: true
    cdb.new('http://127.0.0.1:5984/_replicator').put replicant
