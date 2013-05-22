#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# The host records in the provisioning database may contain
# attachment scripts, whose job it is to maintain
# invariants inside the given host.

# Main

pico = require 'pico'
ccnq3 = require 'ccnq3'

ccnq3.config (config) ->

  source_uri = config.provisioning.host_couchdb_uri

  # Start replication
  if config.admin?.system
    ccnq3.log "Not replicating from manager."
  else
    if not source_uri?
      ccnq3.log "Missing provisioning.host_couchdb_uri, terminating."
      return
    target_uri = config.provisioning.local_couchdb_uri
    if target_uri?
      filter = config.provisioning.filter ? 'host/replication'
      filter_params =
          sip_domain_name: config.sip_domain_name
      pico.replicate source_uri, target_uri, config.replicate_interval, filter, filter_params
    else
      ccnq3.log "Missing provisioning.local_couchdb_uri, not replicating."
