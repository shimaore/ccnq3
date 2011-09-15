###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

# This couchapp is automatically inserted in a user database
# by the track_users agent.

ddoc =
  _id: '_design/authorize'

module.exports = ddoc

# Validate that the operation is authorized for this user.
ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->

  user_match = (account,message) ->
    for prefix in userCtx.roles
      do (prefix) ->
        if ("update:provisioning:"+account).substring(0,prefix.length) is prefix
          return
    throw {forbidden : message||"No access to this account"}

  user_is = (role) ->
    return userCtx.roles.indexOf(role) >= 0

  # Only admins or confirmed users may modify documents.
  # (Newly registered users may not.)
  if not user_is('_admin') and not user_is('confirmed')
    throw {forbidden : "Not a confirmed user."}

  # Handle delete documents.
  if newDoc._deleted is true

    if oldDoc.type is 'number'
      if not user_is('_admin')
        throw {forbidden: 'Only admins may delete numbers.'}

    # User must have access to document to be able to delete it.
    user_match(oldDoc.account,"Attempt to change document account failed.")

    return

  # Document is not being deleted.

  # User should have access to the account to be able to create or update document inside it.
  user_match(newDoc.account) if newDoc.account?

  # Validate updates
  if oldDoc
    if newDoc.account isnt oldDoc.account
      user_match(oldDoc.account,"Attempt to change document account failed.")

  # Validate create
  if not oldDoc
    if newDoc.type is "number"
      if not user_is('_admin')
        throw {forbidden: 'Only admins may create new numbers.'}

  return
