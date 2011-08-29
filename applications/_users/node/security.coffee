#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

util = require 'util'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

users = cdb.new config.users.couchdb_uri

# Set the security object for the _users database.
users.get '_security', (p)->
  if p.error? then return util.log p.error
  push p.admins.roles,  "users_admin"  if p.admins?.roles.indexOf("users_admin") < 0
  push p.readers.roles, "users_reader" if p.readers?.roles.indexOf("users_reader") < 0
  options =
    method: 'PUT'
    uri: '_security'
    body: p
  users.req options, (r)->
    if r.error? then return util.log p.error
