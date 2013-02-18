#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

## npm-apps.coffee
# Execute a given npm action (such as "install")
# on all ccnq3 `applications` listed in `config.applications`.

path = require 'path'

npm_cmd = '/usr/bin/npm'
operation = process.argv.slice(2)

finalize = ->
  console.log "npm-apps #{operation}: Done."
  process.exit()

log = (application,error) ->
  console.log """
    #{application}: #{if error then 'Failed' else 'OK'}
    """
  if error
    finalize = ->
      throw new Error "#{application} reported an error."

child_process = require 'child_process'

require('ccnq3').config (config) ->

  source = config.source ? path.join __dirname, '..'

  run = (applications) ->
      return finalize() unless applications?.length > 0
      application = applications.shift()
      return finalize() unless application?

      options =
        cwd: path.join source, application
        stdio: ['ignore','pipe','pipe','ignore']
      npm = child_process.spawn npm_cmd, operation, options
      npm.stdout.on 'data', (data) -> process.stdout.write data
      npm.stderr.on 'data', (data) -> process.stderr.write data
      npm.on 'exit', ->
        log "#{operation.join ' '} for #{application}", arguments...
        run applications

  run config.applications
