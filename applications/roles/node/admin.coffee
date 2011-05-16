###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Load Configuration
fs = require('fs')
config_location = 'admin.config'
admin_config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def login_config: login_config

# Load CouchDB
cdb = require process.cwd()+'/../../../lib/cdb.coffee'
def users_cdb: cdb.new (confirm_config.users_couchdb_uri)

def user_is: (role) ->
  return session.roles?.indexOf(role) >= 0

def roles_match: (roles,application,account) ->
  for prefix in roles?
    do (prefix) ->
      if ("#{@application}:#{@account}").substring(0,prefix.length) is prefix
        return true
  return false

def admin_access:
  # CouchDB _admin users are always granted access.
  if user_is('_admin')
    return true
  # Make sure the user is confirmed.
  if not user_is('confirmed')
    send {forbidden: "Not a confirmed user."}
    return false
  # Everything OK
  return true

# REST: Test whether the user has portal admin access.
get '/admin': ->
  if admin_access()
    return {ok: true, roles: session.roles}

# REST: Grant another user access to one of the accounts (or sub account)
#       you have access to.
put '/admin/grant/:application/:user': ->
  if admin_access()

    if not roles_match(session.roles,@application,@account)
      return send {forbidden: "You cannot grant access to this application."}

    users_cdb.get "org.couchdb.user:#{@user}", (p) =>
      # FIXME: should not allow to list users by brute force.
      if p.error?
        return send {error: p.error}

      # Do nothing if the target user already has access to this account.
      if roles_match(p.roles?,@application,@account)
        return send {ok: true}

      p.roles.push "#{@application}:#{@account}"
      users_cdb.put p, (r) ->
        if r.error?
          return send {error: r.error}
        return {ok: true}

# Example of possible values (ideas) for "application":
#   provisioning_ro
#   provisioning_rw
#   billing_ro
#   billing_rw
#   provisioning_endpoint_ro
#   etc.
