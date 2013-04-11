#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3').config (config) ->

  usercode_uri = config.usercode?.couchdb_uri
  if usercode_uri?
    try push_script usercode_uri, 'usercode'

  provisioning_uri = config.provisioning?.couchdb_uri
  if provisioning_uri?
    push_script provisioning_uri, 'main'

  local_provisioning_uri = config.provisioning?.local_couchdb_uri
  if local_provisioning_uri?
    local_provisioning = pico local_provisioning_uri
    local_provisioning.create ->
      local_provisioning.request.put '_revs_limit',body:"2", (e,r,b) =>
        if e? then console.dir error:e, when:"set revs_limit for #{local_provisioning_uri}"
