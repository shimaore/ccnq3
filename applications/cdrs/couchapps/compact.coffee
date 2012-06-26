#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3_config').get (config) ->

  cdrs_uri = config.aggregate?.cdrs_uri
  if cdrs_uri?
    cdrs = pico cdrs_uri
    crds.compact pico.log
