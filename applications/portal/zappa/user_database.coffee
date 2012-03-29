#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  config = null
  require('ccnq3_config').get (c)->
    config

  @get '/u/user-database.json', ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    # Typically target_db_name will be a UUID
    target_db_name = @session.profile.user_database
    if not target_db_name
      return @send error:"No user_database provided."
    target_db_uri  = config.users.userdb_base_uri + '/' + target_db_name
    target_db      = cdb.new target_db_uri

    # Create the database
    target_db.create =>

        # Restrict number of available past revisions.
        revs_limit =
          method: 'PUT'
          uri: '_revs_limit'
          body: 10

        target_db.req revs_limit, (r) =>
          if r.error
            return @send error:r.error

          # Make sure the user can access it.
          target_db.security (p) =>

            p.readers =
              names: [ user_doc.name ]
              roles: [ 'update:user_db:' ] # e.g. voicemail

            @send ok:true
