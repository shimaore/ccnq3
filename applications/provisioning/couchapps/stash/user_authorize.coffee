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

  required = (field, message) ->
    if not newDoc[field]
      throw {forbidden : message || "Document must have a " + field}

  unchanged = (field) ->
    if oldDoc and toJSON(oldDoc[field]) is toJSON(newDoc[field])
      throw {forbidden : "Field can't be changed: " + field}

  user_is = (role) ->
    return userCtx.roles.indexOf(role) >= 0

  # Only admins or confirmed users may modify documents.
  # (Newly registered users may not.)
  if not user_is('_admin') and not user_is('confirmed')
    throw {forbidden : "Not a confirmed user."}

  # Some documents might be tagged "do not delete".
  if newDoc._deleted
    if oldDoc.do_not_delete
      throw {forbidden: 'Document is tagged as do_not_delete.'}

  # Validate the document's account, if present.
  user_match = (account,message) ->
    for prefix in userCtx.roles
      do (prefix) ->
        if ("update:provisioning:"+account).substring(0,prefix.length) is prefix
          return
    throw {forbidden : message||"No access to this account"}

  if doc.account?
    if newDoc._deleted
      # User must have access to document to be able to delete it.
      user_match(oldDoc.account)
    else
      # User should have access to the account to be able to create or update document inside it.
      user_match(newDoc.account)

  # Validate the document's type (always required).
  if not newDoc._deleted
    required('type')
    unchanged('type')
    type = newDoc.type

    # Each document of type T should have a .T record.
    required(type)
    unchanged(type)

    expected_id = type+':'+newDoc[type]
    if newDoc._id isnt expected_id
      throw {forbidden: 'Document ID must be '+expected_id}


  #
  # Code starting here only handles provisioning types.
  #

  provisioning_types = ["number","endpoint","location","host"]
  if provisioning_types.indexOf(type) < 0
    return

  # Account is required for some provisioning types.
  account_required = ["number","endpoint","location"]
  if account_required.indexOf(type) >= 0
    required('account')

  # Handle delete documents.
  if newDoc._deleted is true

    if oldDoc.type is 'number'
      if not user_is('_admin')
        throw {forbidden: 'Only admins may delete numbers.'}

  # Validate create
  if not oldDoc
    if newDoc.type is "number"
      if not user_is('_admin')
        throw {forbidden: 'Only admins may create new numbers.'}

  if oldDoc
    user_match(oldDoc.account)



  # Validate fields
  if type is "endpoint"
    if not newDoc.ip and not newDoc.username
      throw {forbidden: 'IP or Username must be provided.'}

    if newDoc.ip and newDoc.ip.match(/^(192\.168\.|172\.(1[6-9]|2[0-9]|3[12])|10\.|fe80:)/)
      throw {forbidden: 'Invalid IP address.'}
    if newDoc.username
      required("password")

  if type is "host"
    if newDoc.account isnt ''
      throw {forbidden: 'Hosts currently can only be added at the root.'}

  return
