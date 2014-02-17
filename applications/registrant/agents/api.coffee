{ spawn } = require 'child_process'
ccnq3 = require 'ccnq3'
opensips_command = require './opensips-command'
params = require './params'

service = {}

process_command = (port,command,cfg) ->
  kill_service = ->
    service[port].kill 'SIGKILL'
    service[port] = null

  stop_service = ->
    opensips_command port, ":kill:\n"
    if service[port]?
      setTimeout kill_service, 4000
  start_service = ->
    if service[port]?
      ccnq3.log "WARNING in start_service: service already running?"
    shared_megs = 1024
    pkg_megs = 512
    service[port] = spawn '/usr/sbin/opensips', [ '-m', shared_megs, '-M', pkg_megs, '-f', cfg ]

  switch command
    when 'stop'
      do stop_service
    when 'start'
      do start_service
    when 'restart'
      do stop_service
      setTimeout start_service, 5000

module.exports = (command,cb) ->
  unless command.command?
    cb error:"`command` is a required parameter", arguments: command

  ccnq3.config (config) ->
    if command.port?
      switch command.command
        when 'restart registrant'
          c = 'restart'
        when 'start registrant'
          c = 'start'
        when 'stop registrant'
          c = 'stop'
        else
          cb error:"Invalid command", received:command

      p = params {proxy_port:command.port}, config
      process_command command.port+30000, c, p.runtime_opensips_cfg
      cb?()

    else
      switch command.command
        when 'restart all registrant'
          c = 'restart'
        when 'start all registrant'
          c = 'start'
        when 'stop all registrant'
          c = 'stop'
        else
          cb error:"Invalid command", received:command

      for r in config.registrants
        p = params r, config
        process_command command.port+30000, c, p.runtime_opensips_cfg

      cb?()
