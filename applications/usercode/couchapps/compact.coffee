#!/usr/bin/env coffee

pico = require 'pico'

log_error = (e,r,b) ->
  if e? then console.log e
  if not b.ok then console.log b

require('ccnq3_config').get (config)->

  usercode_uri = config.usercode.couchdb_uri
  usercode = pico usercode_uri
  usercode.post '_compact', json:{}, log_error
