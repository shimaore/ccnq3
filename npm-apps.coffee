#!/usr/bin/env coffee

log = (application,error,stdout,stderr) ->
  console.log """
    Completed #{application}:
      stdout: #{stdout}
      stderr: #{stderr}
      exec error: #{error ? 'none'}
    """

operation = process.argv.slice(2).join(' ')

child_process = require 'child_process'

require('ccnq3_config').get (config) ->

  run = (applications) ->
      application = applications.shift()
      return unless application?
      console.log "Running #{operation} for #{application}"

      command = "npm #{operation}"
      options = cwd: "#{config.source}/#{application}"
      child_process.exec command, options, ->
        log "#{operation} for #{application}", arguments...
        run applications

  run config.applications
