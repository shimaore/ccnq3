#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config) ->

  cdr_uri = config.cdr_uri
  if cdr_uri?
    cdr = pico cdr_uri
    cdr.compact pico.log
