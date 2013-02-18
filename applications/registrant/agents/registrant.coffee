#!/usr/bin/env coffee

fs = require 'fs'
qs = require 'querystring'
util = require 'util'
pico = require 'pico'
spawn = require('child_process').spawn
ccnq3 = require('ccnq3')

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

# OpenSIPS registrant service management
service = null
kill_service = ->
  service.kill 'SIGKILL'
  service = null

process_changes = (port,command,cfg) ->
  stop_service = ->
    opensips_command port, ":kill:\n"
    if service?
      setTimeout kill_service, 4000
  start_service = ->
    if service?
      ccnq3.log "WARNING in start_service: service already running?"
    service = spawn '/usr/sbin/opensips', [ '-f', cfg ]

  switch command
    when 'stop'
      do stop_service
    when 'start'
      do start_service
    when 'restart'
      do stop_service
      setTimeout start_service, 5000


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
      process_changes params.mi_port, p.sip_commands.registrant, params.runtime_opensips_cfg

  # At startup, use the current document.
  handler config

  # Then start monitoring forward.
  options =
    since_name: "registrant #{config.host}"
    filter_name: "host/hostname"
    filter_params:
      hostname: config.host

  provisioning.monitor options, handler
