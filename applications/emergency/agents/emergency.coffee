#!/usr/bin/env coffee

fs = require 'fs'
util = require 'util'
pico = require 'pico'
spawn = require('child_process').spawn

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

process_changes = (port,command,cfg) ->
  switch command
    when 'stop'
      opensips_command port, ":kill:\n"
    when 'start'
      spawn '/usr/sbin/opensips', [ '-f', cfg ], stdio:'ignore'


require('ccnq3').config (config) ->

  provisioning = pico config.provisioning.local_couchdb_uri

  handler = (p) ->

    if not p.emergency? then return

    base_path = "./opensips"
    model = 'emergency'

    params = {}
    for _ in ['default.json',"#{model}.json"]
      do (_) ->
        data = JSON.parse fs.readFileSync "#{base_path}/#{_}"
        params[k] = data[k] for own k of data

    params.opensips_base_lib = base_path

    require("#{base_path}/compiler.coffee") params

    # Process any MI commands
    if p.sip_commands?.emergency?
      process_changes params.mi_port, p.sip_commands.emergency, params.runtime_opensips_cfg

  # Start with the current configuration
  handler config

  options =
    since_name: "emergency #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  provisioning.monitor options, handler
