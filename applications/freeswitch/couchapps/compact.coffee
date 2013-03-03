#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.compact_design 'freeswitch', pico.log

  cdr_uri = config.cdr_uri
  if cdr_uri?
    cdr = pico cdr_uri
    cdr.compact pico.log
    cdr.compact_design 'cdr', pico.log
