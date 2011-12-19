#!/usr/bin/env coffee

child_process = require 'child_process'

require('ccnq3_config').get (config) ->
  for application in config.applications
    do (application) ->
      console.log "==== Restart #{application} ===="

      command = '(npm stop >/dev/null 2>&1 || echo) && npm start'
      options = cwd: "#{config.source}/#{application}"
      child_process.exec command, options, (error,stdout,stderr) ->
          console.log "exec error: #{error}" if error?
