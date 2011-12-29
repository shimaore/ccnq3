###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  cdb = require 'cdb'

  # Verify whether a given role is present in the user account.
  user_is = (roles,role) ->
    return roles?.indexOf(role) >= 0

  @helper this_user_is: (role) ->
    return user_is @session.roles, role

  # --- Operations ---

  # operation is either "update" or "access"
  user_may = (roles,operation,source,prefix) ->
    matching = "#{operation}:#{source}:#{prefix}"
    return roles.some (v) ->
      (v).substring(0,matching.length) is matching


  # REST: Grant another user access to one of the accounts (or sub account)
  #       you have access to.

  @helper _admin_handle: (operation,source,prefix,cb)->

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

    if not this_user_may('update','_users',@prefix) and not this_user_is('_admin')
      return @send forbidden: "You do not have administrative access."

    users_cdb = cdb.new config.users.couchdb_uri
    users_cdb.get "org.couchdb.user:#{@user}", (p) =>
      # FIXME: should not allow to list users by brute force.
      if p.error?
        return @send error: p.error

      cb p, (q)=>

        users_cdb.put q, (r) =>
          if r.error?
            return @send error: r.error
          return @send ok: true

  # TODO GET /admin/grant/:user , using a user's "primary account" (the _users' record "account" field).

  # Grant right
  @put '/roles/admin/grant/:user/(update|access)/:source/:prefix': ->
    operation = @params[0]
    source = @params.source
    prefix = @params.prefix
    @_admin_handle operation, (p,cb)=>
      # Do nothing if the target user already has access to this account.
      # (Including because it has access to a parent.)
      if user_may p.roles,operation,source,prefix
          return @send ok:true

      # Add prefix to access for the proper operation
      p.roles.push "#{operation}:#{source}:#{prefix}"
      cb(p)

  # Drop right
  @del '/roles/admin/grant/:user/(update|access)/:source/:prefix': ->
    operation = params[0]
    source = @params.source
    prefix = @params.prefix
    @_admin_handle operation, (p,cb)=>
      if not user_may p.roles,operation,source,prefix
          return @send ok:true

      # Remove all access to prefix or its children.
      matching = "#{operation}:#{source}:#{prefix}"
      p.roles = p.roles.filter (v)->
        not ( (v).substring(0,matching.length) is matching )
      cb(p)

  # Host role
  @put '/roles/admin/grant/:user/host': ->
    @_admin_handle 'host', (p,cb)=>
      if not p.name.match /^host@/
        return @send error:'User must be a host'

      if 'host' in p.roles
        return @send ok:true

      p.roles.push 'host'
      cb(p)
