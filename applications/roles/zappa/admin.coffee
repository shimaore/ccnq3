###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  pico = require 'pico'

  # Verify whether a given role is present in the user account.
  user_is = (roles,role) ->
    return roles?.indexOf(role) >= 0

  @helper this_user_is: (role) ->
    return user_is @session.roles, role

  user_id = (username) ->
    "org.couchdb.user:#{username}"

  # --- Operations ---

  # operation is either "update" or "access"
  user_may = (roles,operation,source,prefix) ->
    matching = "#{operation}:#{source}:#{prefix}"
    return roles.some (v) ->
      (v).substring(0,matching.length) is matching


  # REST: Grant another user access to one of the accounts (or sub account)
  #       you have access to.
  @helper _admin_auth: (operation,source,prefix,cb) ->

    this_user_is = (role) =>
      user_is @session.roles, role

    this_user_may = (operation,source,prefix) =>
      user_may @session.roles,operation,source,prefix

    ready = =>
      # User must be logged in.
      if not @session.logged_in?
        @send forbidden: "Not logged in"
        return false
      # CouchDB _admin users are always granted access.
      if this_user_is '_admin'
        return true
      # Make sure the user is confirmed.
      if not this_user_is 'confirmed'
        @send forbidden: "Not a confirmed user."
        return false
      # Everything OK
      return true

    if not ready()
      return

    if not this_user_may operation,source,prefix
      return @send forbidden: "You cannot grant access you do not have."

    if not this_user_may('update','_users',prefix) and not this_user_is('_admin')
      return @send forbidden: "You do not have administrative access."

    do cb

  @helper _admin_handle: (operation,source,prefix,cb)->
    @_admin_auth operation,source,prefix, =>

      require('ccnq3').config (config)=>

        users_db = pico config.users.couchdb_uri
        users_db.get user_id(@params.user), (e,r,p) =>

          if e?
            return @send error:e

          p.roles ?= []

          cb p, (q)=>

            users_db.put q, (e) =>
              if e?
                return @send error: e
              return @send ok: true

  # TODO GET /admin/grant/:user , using a user's "primary account" (the _users' record "account" field).

  # Create user
  @post '/ccnq3/roles/admin/adduser': ->
    operation = 'update'
    source = '_users'
    prefix = ''
    @_admin_auth operation, source, prefix, =>

      require('ccnq3').config (config)=>

        p =
          _id: user_id @body.name
          type: 'user'
          roles: []
          password: @body.password
          name: @body.name

        users_db = pico config.users.couchdb_uri
        users_db.put user_id(@body.name), json:p, (e,r,p) =>
          @send status: r.statusCode, data: p

  # Grant right
  @put '/ccnq3/roles/admin/grant/:user/:operation(update|access)/:source/:prefix?': ->
    operation = @params.operation
    source = @params.source
    prefix = @params.prefix ? ''
    @_admin_handle operation, source, prefix, (p,cb)=>
      # Do nothing if the target user already has access to this account.
      # (Including because it has access to a parent.)
      if user_may p.roles,operation,source,prefix
          return @send ok:true

      # Add prefix to access for the proper operation
      p.roles.push "#{operation}:#{source}:#{prefix}"
      cb(p)

  # Drop right
  @del '/ccnq3/roles/admin/grant/:user/:operation(update|access)/:source/:prefix?': ->
    operation = @params.operation
    source = @params.source
    prefix = @params.prefix ? ''
    @_admin_handle operation, source, prefix, (p,cb)=>
      if not user_may p.roles,operation,source,prefix
          return @send ok:true

      # Remove all access to prefix or its children.
      matching = "#{operation}:#{source}:#{prefix}"
      p.roles = p.roles.filter (v)->
        not ( (v).substring(0,matching.length) is matching )
      cb(p)

  # Host role
  @put '/ccnq3/roles/admin/grant/:user/host': ->
    operation = 'update'
    source = 'host'
    prefix = ''
    @_admin_handle operation, source, prefix, (p,cb)=>
      if not p.name.match /^host@/
        return @send error:'User must be a host'

      if user_is p.roles, 'host'
        return @send ok:true

      p.roles.push 'host'
      cb(p)

  # Confirmed (necessary since system users cannot confirm).
  @put '/ccnq3/roles/admin/grant/:user/confirmed': ->
    operation = 'update'
    source = '_users'
    prefix = ''
    @_admin_handle operation, source, prefix, (p,cb)=>
      if user_is p.roles, 'confirmed'
        return @send ok:true

      p.roles.push 'confirmed'
      cb(p)
