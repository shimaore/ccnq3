#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

couchapp = require 'couchapp'

push_script = (uri,script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

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
  util.log "Processing changes for #{user_doc.name}"
  target_db_name = user_doc.user_database
  if not target_db_name
    return util.log "No user_database provided for #{user_doc.name}"
  target_db_uri  = config.users.userdb_base_uri + '/' + target_db_name
  target_db      = cdb.new target_db_uri

  target_db.exists (it_does_exist) ->
    if user_doc.deleted
      # Nothing to do if the database does not exist
      return if not it_does_exist
      # Remove the database
      util.log "Removing database for #{user_doc.name}"
      target_db.erase()
      return

    # Nothing to do if the database already exists
    return if it_does_exist

    # Create the database
    target_db.create ->

      # Push the "user" couchapp into the database
      push_script target_db_uri, 'user_authorize', -> push_script target_db_uri, 'user_app', ->

        # Make sure the user can access it.
        target_db.security (p) ->

          p.readers =
            names: [ user_doc.name ]

        # TODO verify that this can actually be done (body is not JSON)
        revs_limit =
          method: 'PUT'
          uri: '_revs_limit'
          body: "0"

        target_db.req revs_limit, (r) ->
          if r.error then return util.log r.error
