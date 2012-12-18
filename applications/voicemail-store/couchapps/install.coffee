#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3').config (config) ->

  provisioning_uri = config.provisioning?.couchdb_uri
  if provisioning_uri?
    push_script provisioning_uri, 'main'

  users_uri = config.users?.couchdb_uri
  if users_uri?
    push_script users_uri, 'users'
