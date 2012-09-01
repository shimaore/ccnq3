#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3_config') (config)->

  usercode_uri = config.usercode.couchdb_uri
  usercode = pico usercode_uri
  usercode.compact pico.log
