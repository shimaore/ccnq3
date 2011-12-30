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

request = require 'request'
qs = require 'querystring'
cdb_changes = require 'cdb_changes'

require('ccnq3_config').get (config) ->

  # Initiate replication (_replicator does not work).
  replicate = ->

    # provisioning.couchdb_uri MUST be "http://127.0.0.1:5984/provisioning"
    expected = "http://127.0.0.1:5984/provisioning"
    source_uri = config.provisioning.host_couchdb_uri
    target_uri = config.provisioning.local_couchdb_uri

    if target_uri isnt expected
      console.log "provisioning.local_couchdb_uri should be #{expected}"
      return
    if not source_uri
      console.log "provisioning.host_couchdb_uri is required"
      return

    replicator = "http://127.0.0.1:5984/_replicate"
    replicant =
      # _id:    'ccnq3_provisioning'   # Only when using _replicator
      source: source_uri
      target: 'provisioning' # local target
      create_target: true
      continuous: true

    # Still a bug? CouchDB replication can't authenticate properly, the Base64 contains %40 litteraly...
    url = require 'url'
    qs = require 'querystring'
    source = url.parse replicant.source
    replicant.source = url.format
      protocol: source.protocol
      hostname: source.hostname
      port:     source.port
      pathname: source.pathname

    [username,password] = source.auth?.split /:/
    username = qs.unescape username if username?
    password = qs.unescape password if password?

    if username? or password?
      username ?= ''
      password ?= ''
      basic = new Buffer("#{username}:#{password}")
      replicant.source =
        url: replicant.source
        headers:
          "Authorization": "Basic #{basic.toString('base64')}"
    # /CouchDB bug

    cdb = require 'cdb'
    cdb.new(replicator).post replicant

  if config.admin?.system
    console.log "Not replicating from manager"
  else
    do replicate

  # Main agent code

  options =
    uri: config.provisioning.host_couchdb_uri
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  new_config = config

  cdb_changes.monitor options, (p) ->
    if p.error? then return util.log(p.error)

    [old_config,new_config] = [new_config,p]

    if new_config._attachments?

      base_uri = new_config.provisioning.host_couchdb_uri + '/' + qs.escape "host@#{new_config.host}"

      for attachment_name, info in new_config._attachments
        request base_uri + '/' + qs.escape attachment_name, (err,code) ->
          if err
            return util.log err

          handler[info.content_type]? code, old_config, new_config
