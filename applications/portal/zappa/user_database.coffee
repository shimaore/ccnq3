#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  cdb = require 'cdb'
  pico = require 'pico'

  config = null
  require('ccnq3_config').get (c)->
    config = c

  @get '/u/user-database.json', ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    # Typically target_db_name will be a UUID
    target_db_name = @session.profile.user_database
    if not target_db_name
      return @send error:"No user database is defined."
    target_db_uri  = config.users.userdb_base_uri + '/' + target_db_name
    target_db      = cdb.new target_db_uri

    # Create the database
    target_db.create =>

        # We do not check the return code:
        # it's OK if the database already exists.

        # Restrict number of available past revisions.
        pico(target_db_uri).put '_revs_limit',body:"10", (e,r,b) =>
          if e
            return @send error:e

          # Make sure the user can access it.
          target_db.security (p) =>

            p.readers ?= {}

            p.readers.names ?= []
            unless @session.logged_in in p.readers.names
              p.readers.names.push @session.logged_in

            p.readers.roles = [ 'update:user_db:' ] # e.g. voicemail

            @send ok:true
