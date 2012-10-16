#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config)->

  location_uri = config.opensips_proxy?.usrloc_uri ? 'http://127.0.0.1:5984/location'
  location = pico location_uri
  location.compact pico.log
