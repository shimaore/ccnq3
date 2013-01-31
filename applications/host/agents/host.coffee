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
ccnq3 = require 'ccnq3'

ccnq3.config (config) ->

  source_uri = config.provisioning.host_couchdb_uri

  # Start replication
  if config.admin?.system
    ccnq3.log "Not replicating from manager."
    source_uri ?= config.provisioning.couchdb_uri
  else
    if not source_uri?
      ccnq3.log "Missing provisioning.host_couchdb_uri, terminating."
      return
    target_uri = config.provisioning.local_couchdb_uri
    if target_uri?
      pico.replicate source_uri, target_uri, config.replicate_interval
    else
      ccnq3.log "Missing provisioning.local_couchdb_uri, not replicating."

  # Main agent code
  return unless source_uri?

  src = pico source_uri
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
