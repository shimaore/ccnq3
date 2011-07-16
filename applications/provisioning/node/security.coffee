#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

util = require 'util'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

provisioning = cdb.new config.provisioning.couchdb_uri

# Set the security object for the provisioning database.
provisioning.get '_security', (p)->
  if p.error? then return util.log p.error
  push p.admins.roles, "provisioning_admin"   if p.admins?.roles.indexOf("provisioning_admin") < 0
  push p.readers.roles, "provisioning_reader" if p.readers?.roles.indexOf("provisioning_reader") < 0
  options =
    method: 'PUT'
    uri: '_security'
    body: p
  provisioning.req options, (r)->
    if r.error? then return util.log p.error

