#!/usr/bin/env coffee

pico = require 'pico'
ccnq3 = require 'ccnq3'
{api} = require './api'

dgram = require 'dgram'
opensips_command = (port,command) ->
  # Connect to the MI datagram port
  # Send command
  message = new Buffer(command)
  client = dgram.createSocket "udp4"
  client.send message, 0, message.length, port, "127.0.0.1", (err, bytes) ->
    # FIXME we might receive data (and might want to report it)
    # FIXME the proper way to do so is to collect it then implement a timeout (say 1s)
    #       to declare the UDP session over with.
    client.close()


# Agent main process
ccnq3.config (config) ->

  provisioning = pico config.provisioning.local_couchdb_uri

  handler = (p) ->

    if not p.registrant? then return

    base_path = "./opensips"
    model = 'registrant'

    params = require('./params') p

    # Build the configuration file.
    require("#{base_path}/compiler.coffee") params

    # Process any MI commands
    if p.sip_commands?.registrant?
      api[p.sip_commands.registrant]?.do()

  # At startup, use the current document.
  handler config

  # Then start monitoring forward.
  options =
    since_name: "registrant #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  provisioning.monitor options, handler
