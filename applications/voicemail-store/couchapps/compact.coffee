#!/usr/bin/env coffee

pico = require 'pico'

require('ccnq3').config (config)->

  provisioning_uri = config.provisioning?.couchdb_uri
  if provisioning_uri?
    pico(provisioning_uri).compact_design 'main', pico.log

  users_uri = config.users?.couchdb_uri
  if users_uri?
    pico(users_uri).compact_design 'users', pico.log
