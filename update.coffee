#!/usr/bin/env coffee
# (c) 2011 Stephane Alnet
# License: APGL3+

child_process = require 'child_process'

# Changes in the update file are idempotent (for the same release).
require('ccnq3_config').get (config) ->
  for application in config.applications
    do (application) ->
      console.log "==== Update #{application} ===="
      options = cwd: "#{config.source}/#{application}"
      callback = (error,stdout,stderr) ->
        console.log "stdout: #{stdout}\n"
        console.log "stderr: #{stderr}\n"
        console.log "exec error #{error}\n" if error?

      child_process.exec "npm install", options, ->
        callback arguments...
        if config.admin?.system
          child_process.exec "npm run-script couchapps", options, callback
