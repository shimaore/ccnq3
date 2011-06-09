###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Load Configuration
fs = require('fs')
config_location = 'admin.config'
admin_config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def admin_config: admin_config

# Load CouchDB
cdb = require process.cwd()+'/../../../lib/cdb.coffee'
def users_cdb: cdb.new (admin_config.users_couchdb_uri)
def databases_cdb: cdb.new (admin_config.databases_couchdb_uri)

# REST: required: initialize an admin session
get '/admin': ->
  if not session.logged_in?
    return send forbidden: "Not logged in"

  users_cdb.get "org.couchdb.user:#{session.logged_in}", (p) =>
    session.admin = p
    session.admin.access ?= {}
    session.admin.update ?= {}
    return send p


# Verify whether a given role is present in the user account.
def _user_is: (doc,role) ->
  return doc.roles?.indexOf(role) >= 0

def user_is: (role) ->
  return _user_is session

def _ready: ()->
  # CouchDB _admin users are always granted access.
  if user_is('_admin')
    return true
  # Make sure the user is confirmed.
  if not user_is('confirmed')
    send forbidden: "Not a confirmed user."
    return false
  # Make sure we have all data available
  if not session.admin?
    send forbidden: "Not ready for admin session."
    return false
  # Everything OK
  return true

# --- Operations ---

# operation is either "update" or "access"
def _user_may: (doc,operation,source,account) ->
  return doc?[operation]?[source]?.some (prefix) ->
    (account).substring(0,prefix.length) is prefix

def user_may: (operation,source,account) ->
  _user_may(session.admin,operation,source,account)


# REST: Grant another user access to one of the accounts (or sub account)
#       you have access to.

def _admin_handle: (operation,cb)->

  if not _ready()
    return

  if not user_may(@operation,@source,@prefix)
    return send forbidden: "You cannot grant access you do not have."

  if not user_may('update','_users',@prefix) and not user_is('_admin')
    return send forbidden: "You do not have administrative access."

  users_cdb.get "org.couchdb.user:#{@user}", (p) =>
    # FIXME: should not allow to list users by brute force.
    if p.error?
      return send error: p.error

    cb p, (q)->

      # Map the new content to roles for the user.
      q.roles = q.roles.filter (v)-> not v.match /^(access|update):/

      # These are used by the replicated databases to allow access.
      for source, prefixes of user_doc.access
        q.roles.push "access:#{source}:#{prefix}" for prefix in prefixes

      # These are used by the primary databases' validate_doc_update
      for source, prefixes of user_doc.update
        q.roles.push "update:#{source}:#{prefix}" for prefix in prefixes

      users_cdb.put q, (r) ->
        if r.error?
          return send error: r.error
        return send ok: true

# Grant right
put '/admin/grant/:user/(update|access)/:source/:prefix': ->
  _admin_handle params[0], (p,cb)->
    # Do nothing if the target user already has access to this account.
    # (Including because it has access to a parent.)
    if _user_may(p,@operation,@source,@prefix)
        return send ok:true

    # Add prefix to access for the proper operation
    p[@operation][@source].push @prefix
    cb(p)

# Drop right
del '/admin/grant/:user/(update|access)/:source/:prefix': ->
  _admin_handle params[0], (p,cb)->
    if not _user_may(p,@operation,@source,@prefix)
        return send ok:true

    # Remove all access to prefix or its children.
    p[@operation][@source] = p[@operation][@source].filter (v)->
      not ( (v).substring(0,prefix.length) is prefix )
    cb(p)
