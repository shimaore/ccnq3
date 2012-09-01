#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

## npm-apps.coffee
# Execute a given npm action (such as "install")
# on all ccnq3 `applications` listed in `config.applications`.

finalize = ->
  console.log "Done."

log = (application,error) ->
  console.log """
    #{application}: #{if error then 'Failed' else 'OK'}
    """
  if error
    finalize = ->
      throw new Error "#{application} reported an error."

npm_cmd = '/usr/bin/npm'
operation = process.argv.slice(2)

child_process = require 'child_process'

require('ccnq3_config') (config) ->

  source = config.source ? __dirname

  run = (applications) ->
      return finalize() unless applications?.length > 0
      application = applications.shift()
      return finalize() unless application?

      options =
        cwd: "#{source}/#{application}"
        stdio: ['ignore','pipe','pipe']
      npm = child_process.spawn npm_cmd, operation, options
      npm.stdout.on 'data', (data) -> process.stdout.write data
      npm.stderr.on 'data', (data) -> process.stderr.write data
      npm.on 'exit', ->
        log "#{operation.join ' '} for #{application}", arguments...
        run applications

  run config.applications
