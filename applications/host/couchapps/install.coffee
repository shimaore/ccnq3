#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3').config (config) ->

  usercode_uri = config.usercode?.couchdb_uri
  if usercode_uri?
    push_script usercode_uri, 'usercode'

  provisioning_uri = config.provisioning?.couchdb_uri
  if provisioning_uri?
    push_script provisioning_uri, 'main'

  # This is redundant with what host_cli does, but is consistent with
  # how this is done for other databases.
  if config.provisioning?.local_couchdb_uri?
    local_provisioning_uri = config.provisioning.local_couchdb_uri
    local_provisioning = pico provisioning_uri
    local_provisioning.create ->
