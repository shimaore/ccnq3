#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
require('ccnq3_config').get (config)->

  # Set the security object for the _users source database.
  users_uri = config.users.couchdb_uri
  users = cdb.new users_uri
  users.security (p)->
    p.admins ||= {}
    p.admins.roles ||= []
    p.admins.roles.push("users_admin")   if p.admins.roles.indexOf("users_admin") < 0
    p.readers ||= {}
    p.readers.roles ||= []
    p.readers.roles.push("users_writer") if p.readers.roles.indexOf("users_writer") < 0
    p.readers.roles.push("users_reader") if p.readers.roles.indexOf("users_reader") < 0

  # Installation on source ('_users') database
  push_script users_uri, './main'

  # Installation into usercode database
  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, './usercode'
