#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3_config').get (config)->

  provisioning_uri = config.provisioning.couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.compact pico.log
