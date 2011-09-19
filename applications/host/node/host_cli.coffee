#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Create a username for the new host's main process so that it can bootstrap its own installation.
host = require './host.coffee'

# Load Configuration
ccnq3_config = require 'ccnq3_config'
ccnq3_config.get (config) ->

  # Install the local (bootstrap) host in the database.
  hostname = config.host

  host.record config, hostname, config.users.couchdb_uri, config.provisioning.couchdb_uri, (new_config,cb)->
      ccnq3_config.update new_config

      cb? new_config
