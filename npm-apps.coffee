#!/usr/bin/env coffee

log = (application,error,stdout,stderr) ->
  console.log """
    #{application}: #{error ? 'OK'}
    """
  throw error if error?

operation = process.argv.slice(2).join(' ')

child_process = require 'child_process'

require('ccnq3_config').get (config) ->

  source = config.source ? __dirname

  run = (applications) ->
      return unless applications?.length > 0
      application = applications.shift()
      return unless application?

      command = "npm #{operation}"
      options = cwd: "#{source}/#{application}"
      child_process.exec command, options, ->
        log "#{operation} for #{application}", arguments...
        run applications

  run config.applications
