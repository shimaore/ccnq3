###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  pico = require 'pico'

  config = null
  require('ccnq3_config').get (c) ->
    config = c

  @get '/u/profile.json': ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    users_db = pico config.users.couchdb_uri
    users_db.retrieve "org.couchdb.user:#{@session.logged_in}", (e,x,r) =>
      if e?
        return @send error:e

      user_is = (role) ->
        return r.roles.indexOf(role) >= 0

      @session.user_database = r.user_database
      @session.profile = r.profile
      # Allow the user to know the location of their database.
      r.profile.userdb_base_uri = config.users.public_userdb_base_uri
      r.profile.user_database = r.user_database
      r.profile.user_name = @session.logged_in

      if user_is 'confirmed'
        return @send r.profile

      r.roles.push 'confirmed'
      @session.roles = r.roles
      users_db.update r, (e) =>
        if e?
          return @send error:e

        @send r.profile
