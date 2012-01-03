#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

cfg = require 'ccnq3_config'
cfg.get (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = cdb.new provisioning_uri
  provisioning.create ->
    push_script provisioning_uri, 'freeswitch'

  # FIXME Need centralized CDR system.
  cdr_uri = 'http://127.0.0.1:5984/cdr'
  cdr = cdb.new cdr_uri
  cdr.create ->
    # Need the callback to run.
