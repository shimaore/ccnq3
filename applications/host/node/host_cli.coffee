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

  # Install the local (bootstrap/master) host in the database.
  hostname = config.host

  users = cdb.new config.users.couchdb_uri

  host.create_user users, hostname, (password) ->

    provisioning_uri = config.provisioning.couchdb_uri
    provisioning = cdb.new provisioning_uri

    host.update_config provisioning_uri, provisioning, config, (config) ->

      ccnq3_config.update config
