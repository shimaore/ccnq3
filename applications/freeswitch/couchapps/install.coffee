#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3').config (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.create ->
    push_script provisioning_uri, 'freeswitch'

  cdr_uri = config.cdr_uri ? 'http://127.0.0.1:5984/cdr'
  cdr = pico cdr_uri
  cdr.create ->
    push_script cdr_uri, 'cdr'
