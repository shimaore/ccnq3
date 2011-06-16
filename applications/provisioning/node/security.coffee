#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

util = require 'util'
cdb = require 'cdb'
users = cdb.new "#{process.env.CDB_URI}/provisioning"

# Set the security object for the _users database.
cdb.get '_security', (p)->
  if p.error? then return util.log p.error
  push p.admins.roles, "provisioning_admin"   if p.admins?.indexOf("provisioning_admin") < 0
  push p.readers.roles, "provisioning_reader" if p.readers?.indexOf("provisioning_reader") < 0
  cdb.put '_security', p, (r)->
    if r.error? then return util.log p.error

