#!/usr/bin/env coffee

fs = require 'fs'
util = require 'util'
cdb_changes = require 'cdb_changes'

last_rev = ''

require('ccnq3_config').get (config) ->
  options =
    uri: config.provisioning.host_couchdb_uri

  cdb_changes.monitor options, (p) ->
    if p.error? then return util.log(p.error)
    if p._rev is last_rev then return util.log "Duplicate revision"
    last_rev = p._rev

    if not p.registrant? then return

    base_path = "./opensips"
    model = 'registrant'

    params = {}
    for _ in ['default.json',"#{model}.json"]
      do (_) ->
        data = JSON.parse fs.readFileSync "#{base_path}/#{_}"
        params[k] = data[k] for own k of data

    params.opensips_base_lib = base_path

    # Where do we send INVITE messages?
    params.local_ipv4 = p.registrant.local_ipv4
    params.local_port = p.registrant.local_port

    require("#{base_path}/compiler.coffee") params
