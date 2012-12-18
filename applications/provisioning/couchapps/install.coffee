#!/usr/bin/env coffee

couchapp = require 'couchapp'
pico = require 'pico'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

ccnq3 = require 'ccnq3'
ccnq3.config (config)->

  usercode_uri = config.usercode?.couchdb_uri
  if usercode_uri?
    try push_script usercode_uri, 'usercode'

  # If the database already exists
  provisioning_uri = config.provisioning?.couchdb_uri
  if provisioning_uri
    ccnq3.db.security provisioning_uri, 'provisioning', true
    push_script provisioning_uri, 'main'
    return

  # Otherwise create the database
  return unless config.install?.provisioning?.couchdb_uri? or config.admin?.couchdb_uri?
  provisioning_uri = config.install?.provisioning?.couchdb_uri ? config.admin.couchdb_uri + '/provisioning'
  provisioning = pico provisioning_uri
  provisioning.create ->

    ccnq3.db.security provisioning_uri, 'provisioning', true
    push_script provisioning_uri, 'main'

    # Save the new URI in the configuration
    config.provisioning ?= {}
    config.provisioning.couchdb_uri = provisioning_uri
    ccnq3.config.update config

    # Save the local host's (=manager) record in the newly-created database.
    provisioning.update config, ->
