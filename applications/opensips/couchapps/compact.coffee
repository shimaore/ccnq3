#!/usr/bin/env coffee

pico = require 'pico'

log_error = (e,r,b) ->
  if e? then console.log e
  if not b.ok then console.log b

require('ccnq3_config').get (config)->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.post '_compact', json:{}, log_error

  location_uri = config.opensips_proxy?.usrloc_uri ? 'http://127.0.0.1:5984/location'
  location = pico location_uri
  location.post '_compact', json:{}, log_error
