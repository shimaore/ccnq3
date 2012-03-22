#!/usr/bin/env coffee

pico = require 'pico'

log_error = (e,r,b) ->
  if e? then console.log e
  if not b.ok then console.log b

require('ccnq3_config').get (config) ->

  cdrs_uri = config.aggregate?.cdrs_uri
  if cdrs_uri?
    cdrs = pico cdrs_uri
    cdrs.post '_compact', json:{}, log_error
