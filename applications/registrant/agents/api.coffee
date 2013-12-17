{ spawn } = require 'child_process'
ccnq3 = require 'ccnq3'
opensips_command = require './opensips-command'
params = require './params'

service = null
kill_service = ->
  service.kill 'SIGKILL'
  service = null

process_command = (port,command,cfg) ->
  stop_service = ->
    opensips_command port, ":kill:\n"
    if service?
      setTimeout kill_service, 4000
  start_service = ->
    if service?
      ccnq3.log "WARNING in start_service: service already running?"
    shared_megs = 1024
    pkg_megs = 512
    service = spawn '/usr/sbin/opensips', [ '-m', shared_megs, '-M', pkg_megs, '-f', cfg ]

  switch command
    when 'stop'
      do stop_service
    when 'start'
      do start_service
    when 'restart'
      do stop_service
      setTimeout start_service, 5000

@api =
  start:
    description: 'Start the registrant OpenSIPS process'
    category: 'registrant'
    do: (cb) ->
      ccnq3.config (p) ->
        if not p.registrant? then return
        p = params p
        process_command p.mi_port, 'start', p.runtime_opensips_cfg
        cb?()

  restart:
    description: 'Restart the registrant OpenSIPS process'
    category: 'registrant'
    do: (cb) ->
      ccnq3.config (p) ->
        if not p.registrant? then return
        p = params p
        process_command p.mi_port, 'restart', p.runtime_opensips_cfg
        cb?()

  stop:
    description: 'Stop the registrant OpenSIPS process'
    category: 'registrant'
    do: (cb) ->
      ccnq3.config (p) ->
        if not p.registrant? then return
        p = params p
        process_command p.mi_port, 'stop', p.runtime_opensips_cfg
        cb?()
