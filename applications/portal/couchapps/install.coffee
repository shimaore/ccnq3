#!/usr/bin/env coffee

couchapp = require 'couchapp'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

require('ccnq3_config').get (config)->

  users_uri = config.users.couchdb_uri
  push_script users_uri, 'main'

  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'
