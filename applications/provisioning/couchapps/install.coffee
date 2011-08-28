#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

# Load Configuration
config = require('ccnq3_config').config

uri = config.provisioning.couchdb_uri

# Create the provisioning database.
cdb.new(uri).create()

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
    if r.error? then return util.log r.error

# Install the couchapp scripts.
push_script = (script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# These couchapps are available to provisioning_admin (and _admin) users.
push_script 'replicate'
