#!/usr/bin/env coffee

child_process = require 'child_process'

require('ccnq3_config').get (config) ->

  return unless config.traces?.interfaces?.length > 0

  for intf in config.traces.interfaces
    do (intf) ->
      child_process.exec """
        daemon -n 'ccnq3_traces_#{intf}' -o daemon.debug -r --stop
      """
