#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

util = require 'util'
cdb = require 'cdb'

# Load Configuration
fs = require('fs')
config_location = process.env.npm_package_config_bootstrap_file
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

provisioning = cdb.new "#{config.couchdb_uri}/provisioning"

# Set the security object for the provisioning database.
provisioning.get '_security', (p)->
  if p.error? then return util.log p.error
  push p.admins.roles, "provisioning_admin"   if p.admins?.indexOf("provisioning_admin") < 0
  push p.readers.roles, "provisioning_reader" if p.readers?.indexOf("provisioning_reader") < 0
  provisioning.put '_security', p, (r)->
    if r.error? then return util.log p.error

