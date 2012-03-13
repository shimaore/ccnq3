#!/usr/bin/env coffee

pico = require 'pico'

log_error = (e,r,b) ->
  if e? then console.log e
  if not b.ok then console.log b

require('ccnq3_config').get (config)->

  provisioning_uri = config.provisioning.couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.post '_compact', json:{}, log_error
