#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config) ->

  monitor_uri = config.monitor?.couchdb_uri
  if monitor_uri?
    monitor = pico monitor_uri
    monitor.compact pico.log
    monitor.compact_design 'replicate', pico.log
