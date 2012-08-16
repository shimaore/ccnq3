#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# The host records in the provisioning database may contain
# attachment scripts, whose job it is to maintain
# invariants inside the given host.

util = require 'util'

handler = require './handlers'

# Main

qs = require 'querystring'

pico = require 'pico'

require('ccnq3_config').get (config) ->

  # Start replication
  if config.admin?.system
    console.log "Not replicating from manager"
  else
    source_uri = config.provisioning.host_couchdb_uri
    target_uri = config.provisioning.local_couchdb_uri
    pico.replicate source_uri, target_uri, config.replicate_interval

  # Main agent code

  src = pico config.provisioning.host_couchdb_uri
  options =
    since_name: "host #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  new_config = config

  src.monitor options, (p) ->

    [old_config,new_config] = [new_config,p]

    if new_config._attachments?

      base_uri = new_config.provisioning.host_couchdb_uri + '/' + qs.escape "host@#{new_config.host}"
      base = pico.request base_uri

      for attachment_name, info in new_config._attachments
        base qs.escape attachment_name, (err,response,code) ->
          if err
            return util.log err

          handler[info.content_type]? code, old_config, new_config
