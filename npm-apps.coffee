#!/usr/bin/env coffee

log = (application,error,stdout,stderr) ->
  console.log "#{application} stdout: #{stdout}"
  console.log "#{application} stderr: #{stderr}"
  console.log "#{application} exec error #{error}" if error?

operation = process.argv.slice(2).join(' ')

child_process = require 'child_process'

require('ccnq3_config').get (config) ->
  for application in config.applications
    do (application) ->
      console.log "==== #{operation} #{application} ===="

      command = "npm #{operation}"
      options = cwd: "#{config.source}/#{application}"
      child_process.exec command, options, ->
        log "#{operation} #{application}", arguments...
