#!/usr/bin/env coffee

couchapp = require 'couchapp'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3').config (config)->

  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'
