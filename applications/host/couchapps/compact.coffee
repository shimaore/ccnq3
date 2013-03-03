#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config)->

  if config.provisioning?.local_couchdb_uri?
    provisioning_uri = config.provisioning.local_couchdb_uri
    provisioning = pico provisioning_uri
    provisioning.compact pico.log
    provisioning.compact_design 'host', pico.log
