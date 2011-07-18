#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Create a username for the new host's main process so that it can bootstrap its own installation.
host = require './host.coffee'

# Load Configuration
ccnq3_config = require 'ccnq3_config'
config = ccnq3_config.config

hostname = config.host

host.record hostname, config.users.couchdb_uri, config.provisioning.couchdb_uri, (username,password)->
    url = require 'url'
    p = url.parse "#{config.bootstrap.couchdb_uri}/provisioning"
    delete p.href
    delete p.host
    p.auth = "#{username}:#{password}"

    config.provisioning =
      couchdb_uri: url.format p

    ccnq3_config.update config
