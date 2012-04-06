#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

## npm-apps.coffee
# Execute a given npm action (such as "install")
# on all ccnq3 `applications` listed in `config.applications`.

finalize = ->
  console.log "Done."

log = (application,error,stdout,stderr) ->
  console.log """
    #{application}: #{error ? 'OK'}
    """
  if error?
    finalize = ->
      throw error

operation = process.argv.slice(2).join(' ')

child_process = require 'child_process'

require('ccnq3_config').get (config) ->

  source = config.source ? __dirname

  run = (applications) ->
      return finalize() unless applications?.length > 0
      application = applications.shift()
      return finalize() unless application?

      command = "npm #{operation}"
      options = cwd: "#{source}/#{application}"
      child_process.exec command, options, ->
        log "#{operation} for #{application}", arguments...
        run applications

  run config.applications
