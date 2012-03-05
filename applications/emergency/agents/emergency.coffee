#!/usr/bin/env coffee

fs = require 'fs'
util = require 'util'
cdb = require 'cdb'
cdb_changes = require 'cdb_changes'
spawn = require('child_process').spawn

last_rev = ''

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
      spawn '/usr/sbin/opensips', [ '-f', cfg ]


require('ccnq3_config').get (config) ->

  provisioning = cdb.new config.provisioning.local_couchdb_uri

  options =
    uri: config.provisioning.local_couchdb_uri
    # FIXME: filter, only host records for local host

  cdb_changes.monitor options, (p) ->
    if p.error? then return util.log(p.error)
    if p._rev is last_rev then return util.log "Duplicate revision"
    last_rev = p._rev

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
