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
users.security (p)->
  push p.admins.roles,  "users_admin"  if p.admins?.roles.indexOf("users_admin") < 0
  push p.readers.roles, "users_writer" if p.readers?.roles.indexOf("users_writer") < 0
  push p.readers.roles, "users_reader" if p.readers?.roles.indexOf("users_reader") < 0
