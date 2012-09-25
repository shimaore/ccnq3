#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  pico = require 'pico'

  config = null
  require('ccnq3').config (c)->
    config = c

  @put '/ccnq3/roles/userdb/:name', ->
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
    users_db.view 'replicate', 'userdb', qs: {key:JSON.stringify target_db_name}, (e,r,b) =>
      if e? then return @send error:e

      # Database is not (or no longer) needed
      if not b.rows? or b.rows.length <= 0
        # Remove the database
        target_db.request.del (e,r,b) =>
          if e? then return @send error:e
          @send ok:true
        return

      # Database is needed
      readers_names = (row.value for row in b.rows)

      # Create the database
      target_db.create =>

        # We do not check the return code:
        # it's OK if the database already exists.

        # Restrict number of available past revisions.
        target_db.request.put '_revs_limit',body:"10", (e,r,b) =>
          if e? then return @send error:e

          # Make sure the users can access it.
          target_db.request.get '_security', json:true, (e,r,b) =>
            if e? then return @send error:e

            b.readers ?= {}

            b.readers.names = readers_names
            b.readers.roles = [ 'update:user_db:' ] # e.g. voicemail

            target_db.request.put '_security', json:b, (e,r,b) =>
              if e? then return @send error:e
              @send ok:true
