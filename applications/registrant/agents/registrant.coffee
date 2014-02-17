#!/usr/bin/env coffee

pico = require 'pico'
ccnq3 = require 'ccnq3'
params = require './params'

# Agent main process
ccnq3.config (config) ->

  provisioning = pico config.provisioning.local_couchdb_uri

  handler = (config) ->

    if not config.registrants? then return

    for r in config.registrants
      do (r) ->
        p = params r, config

        # Build the configuration file.
        require("#{base_path}/compiler.coffee") params, config

  # At startup, use the current document.
  handler config

  # Then start monitoring forward.
  options =
    since_name: "registrant #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  provisioning.monitor options, handler

require './amqp-listener'
