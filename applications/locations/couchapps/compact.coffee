#!/usr/bin/env coffee

pico = require 'pico'

log_error = (e,r,b) ->
  if e? then console.log e
  if not b.ok then console.log b

require('ccnq3_config').get (config) ->

  locations_uri = config.aggregate?.locations_uri
  if locations_uri?
    locations = pico locations_uri
    locations.post '_compact', json:{}, log_error
