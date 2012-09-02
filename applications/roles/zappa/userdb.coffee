#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  pico = require 'pico'

  config = null
  require('ccnq3_config').get (c)->
    config = c

  @put '/roles/userdb/:name', ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    # Typically target_db_name will be a UUID
    target_db_name = @request.param 'name'
    if not target_db_name? or not target_db_name.match /^u[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
      return @send error:"No user database is defined."
    target_db_uri  = config.users.userdb_base_uri + '/' + target_db_name
    target_db      = pico target_db_uri

    users_db = pico config.users.couchdb_uri

    # Use the view to gather information about the requested user database.
    users_db.view 'replicate', 'userdb', (e,r,b) =>

      # Database is not needed
      if not b.rows? or b.rows.length <= 0
        @send ok:true

      readers_names = (row.value for row in b.rows)

      # Create the database
      target_db.create =>

        # We do not check the return code:
        # it's OK if the database already exists.

        # Restrict number of available past revisions.
        target_db.put '_revs_limit',body:"10", (e,r,b) =>
          if e
            return @send error:e

          # Make sure the users can access it.
          target_db.get '_security', json:true, (e,r,b) =>
            if e? then return @send error:e

            b.readers ?= {}

            b.readers.names = readers_names
            b.readers.roles = [ 'update:user_db:' ] # e.g. voicemail

            target_db.put '_security', json:b, (e,r,b) =>
              if e? then return @send error:e
              @send ok:true
