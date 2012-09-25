#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config) ->

  locations_uri = config.aggregate?.locations_uri
  if locations_uri?
    locations = pico locations_uri
    locations.compact pico.log
