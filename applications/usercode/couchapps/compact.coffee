#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config)->

  usercode_uri = config.usercode.couchdb_uri
  usercode = pico usercode_uri
  usercode.compact pico.log
