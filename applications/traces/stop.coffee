#!/usr/bin/env coffee

child_process = require 'child_process'

require('ccnq3_config').get (config) ->

  return unless config.traces?.interfaces?.length > 0

  for interface in config.traces.interfaces
    do (interface) ->
      child_process.exec """
        daemon -n 'ccnq3_traces_#{interface}' -o daemon.debug -r --stop
      """
