#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config) ->

  cdr_uri = config.cdr_uri ? 'http://127.0.0.1:5984/cdr'
  cdr = pico cdr_uri
  cdr.compact pico.log
