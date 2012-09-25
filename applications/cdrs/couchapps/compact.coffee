#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config) ->

  cdrs_uri = config.aggregate?.cdrs_uri
  if cdrs_uri?
    cdrs = pico cdrs_uri
    cdrs.compact pico.log
