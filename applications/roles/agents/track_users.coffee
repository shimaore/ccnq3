#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Local configuration file
config = require('ccnq3_config').config

util = require 'util'
qs = require 'querystring'
child_process = require 'child_process'

cdb = require 'cdb'
users_cdb     = cdb.new config.users.couchdb_uri

cdb_changes = require 'cdb_changes'

options =
  uri: config.users.couchdb_uri
  filter_name: 'portal/confirmed'

cdb_changes.monitor options, (user_doc) ->
  if user_doc.error?
    return util.log(user_doc.error)

  # Typically target_db_name will be a UUID
  target_db_name = doc.uuid
  target_db_uri  = config.track_databases.base_cdb_uri + target_db_name
  target_db      = cdb.new target_db_uri

  target_db.exists (it_does_exist) ->
    if user_doc.deleted
      # Nothing to do if the database does not exist
      return if not it_does_exist
      # Remove the database
      target_db.erase
      return

    # Nothing to do if the database already exists
    return if it_does_exist

    # Create the database
    target_db.create ->

      # Make sure the user can access it.
      security_req =
        uri:"_security"
        body:
          # no admin roles => need to be _admin
          readers:
            names: [ user_doc.name ]

      target_db.req security_req, (r) ->
        if r.error
          return util.log(r.error)
