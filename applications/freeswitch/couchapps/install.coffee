#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3').config (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri
  push_script provisioning_uri, 'freeswitch'

  cdr_uri = config.cdr_uri
  if cdr_uri?
    cdr = pico cdr_uri
    cdr.create ->
      push_script cdr_uri, 'cdr'
      cdr.request.put '_revs_limit',body:"2", (e,r,b) =>
        if e? then console.dir failure error:e, when:"set revs_limit for #{cdr_uri}"
