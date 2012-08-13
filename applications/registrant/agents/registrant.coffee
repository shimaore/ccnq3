#!/usr/bin/env coffee

fs = require 'fs'
qs = require 'querystring'
util = require 'util'
pico = require 'pico'
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

  provisioning = pico config.provisioning.local_couchdb_uri

  # FIXME: filter, only host records for local host

  provisioning.monitor (p) ->
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

    qs_host = qs.stringify key: JSON.stringify p.host
    provisioning.get "/_design/registrant/_view/registrant?#{qs_host}", json:true, (e,r,l) ->
      params.uac_entries = ("""
        modparam("uac_registrant","uac","sip:#{p.registrant.remote_ipv4},,sip:00#{row.value.number}@#{p.registrant.remote_ipv4},,00#{row.value.number},#{row.value.password},sip:00#{row.value.number}@#{p.interfaces.primary.ipv4 ? p.host}:5070,,,")\n
      """ for row in l.rows).join ''

      require("#{base_path}/compiler.coffee") params

      # Process any MI commands
      if p.sip_commands?.registrant?
        process_changes params.mi_port, p.sip_commands.registrant, params.runtime_opensips_cfg
