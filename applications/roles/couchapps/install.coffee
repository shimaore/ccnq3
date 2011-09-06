#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

# Set the security object for the _users database.
users = cdb.new config.users.couchdb_uri
users.security (p)->
  push p.admins.roles,  "users_admin"  if p.admins?.roles.indexOf("users_admin") < 0
  push p.readers.roles, "users_writer" if p.readers?.roles.indexOf("users_writer") < 0
  push p.readers.roles, "users_reader" if p.readers?.roles.indexOf("users_reader") < 0

# Installation
uri = config.users.couchdb_uri
couchapp.createApp require("./users"), uri, (app)-> app.push()
