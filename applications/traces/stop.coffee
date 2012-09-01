#!/usr/bin/env coffee

child_process = require 'child_process'

require('ccnq3_config') (config) ->

  return unless config.traces?.interfaces?.length > 0

  for intf in config.traces.interfaces
    do (intf) ->
      child_process.spawn '/usr/bin/daemon', [
        '-n', "ccnq3_traces_#{intf}"
        '-o', "daemon.debug"
        '--stop'
      ], stdio: 'ignore'
