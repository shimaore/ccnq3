#!/usr/bin/env coffee

util = require 'util'
cdb = require 'cdb'
users = cdb.new "#{process.env.CDB_URI}/_users"

# Set the security object for the _users database.
cdb.get '_security', (p)->
  if p.error? then return util.log p.error
  push p.admins.roles, "users_admin"   if p.admins?.indexOf("users_admin") < 0
  push p.readers.roles, "users_reader" if p.readers?.indexOf("users_reader") < 0
  cdb.put '_security', p, (r)->
    if r.error? then return util.log p.error

