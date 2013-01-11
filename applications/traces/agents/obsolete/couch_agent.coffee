#!/usr/bin/env coffee
#
# OBSOLETE
#

pico = require 'pico'

trace_server = require './trace_server'

require('ccnq3').config (config) ->

  db = pico config.provisioning.host_couchdb_uri

  handler = (config) ->
    if config.traces?.run?
      for port, params of config.traces.run
        do (port,params) ->
          trace_server config, port, params

  options =
    since_name: "traces #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  db.monitor options, handler
