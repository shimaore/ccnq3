#!/usr/bin/env coffee
#
## The host records in the provisioning database may contain
# attachment scripts, whose job it is to maintain
# invariants inside the given host.

pico = require 'pico'

trace_server = require './trace_server'

require('ccnq3_config').get (config) ->

  db = pico config.provisioning.host_couchdb_uri

  options =
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  db.monitor options, (doc) ->
    if doc.traces?.run?
      for port, params of doc.traces.run
        do (port,params) ->
          trace_server doc, port, params
