#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3_config') (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.compact pico.log

  cdr_uri = config.cdr_uri ? 'http://127.0.0.1:5984/cdr'
  cdr = pico cdr_uri
  cdr.compact pico.log
