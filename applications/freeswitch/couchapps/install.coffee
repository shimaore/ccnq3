#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

cfg = require 'ccnq3_config'
cfg.get (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  provisioning.put ->
    push_script provisioning_uri, 'freeswitch'

  cdr_uri = config.cdr_uri ? 'http://127.0.0.1:5984/cdr'
  cdr = pico cdr_uri
  cdr.put ->
    push_script cdr_uri, 'cdr'
