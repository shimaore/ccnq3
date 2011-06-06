###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

# Install:
#   coffee -c provisioning-global.coffee
#   couchapp push provisioning-global.js http://127.0.0.1:5984/provisioning

couchapp = require('couchapp')

ddoc =
  _id: '_design/app'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

# http://wiki.apache.org/couchdb/Document_Update_Validation
ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->

  if newDoc._id is "_design/userapp"
    throw {forbidden:'The user application should not be replicated here.'}

  required = (field, message) ->
    if not newDoc[field]
      throw {forbidden : message || "Document must have a " + field}

  unchanged = (field) ->
    if oldDoc and toJSON(oldDoc[field]) is toJSON(newDoc[field])
      throw {forbidden : "Field can't be changed: " + field}

  user_match = (account,message) ->
    for prefix in userCtx.roles
      do (prefix) ->
        if ("account:"+account).substring(0,prefix.length) is prefix
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

    if not user_is('_admin')
      throw {forbidden: 'Only admins may delete documents.'}

    if oldDoc.do_not_delete
      throw {forbidden: 'Document is tagged as do_not_delete.'}

    return
  else
    # Document was not deleted, any tests here?

  required("account")

  # Validate the document's type
  required("type")
  unchanged("type")
  if  type isnt "number" and type isnt "endpoint" and type isnt "location"
    throw {forbidden: 'Invalid type.'}

  # Each document of type T should have a .T record.
  required(newDoc.type)
  unchanged(newDoc.type)
  if newDoc._id isnt newDoc.type+":"+newDoc[newDoc.type]
    throw {forbidden: "Document ID must be #{newDoc.type}:#{newDoc[newDoc.type]}."}

  # User should have access to the account to be able to create or update document inside it.
  user_match(newDoc.account)

  # Validate updates
  if oldDoc
    if newDoc.account isnt oldDoc.account
      user_match(oldDoc.account,"Attempt to change document account failed.")
    # Other updates

  # Validate create
  if not oldDoc
    if newDoc.type is "number"
      if not user_is('_admin')
        throw {forbidden: 'Only admins may create new numbers.'}

  # Validate fields
  if newDoc.type is "endpoint"
    if not newDoc.ip and not newDoc.username
      throw {forbidden: 'IP or Username must be provided.'}

    if newDoc.ip and newDoc.ip.match(/^(192\.168\.|172\.(1[6-9]|2[0-9]|3[12])|10\.|fe80:)/)
      throw {forbidden: 'Invalid IP address.'}
    if newDoc.username
      required("password")


ddoc.filters.user_replication = (doc, req) ->
  # Prefix is required
  if not req.prefix
    return false

  # Only replicate documents, do not replicate _design objects (for example).
  if not doc.account
    return false

  # Replicate documents for which the account is a subset of the prefix.
  if doc.account.substr(0,req.prefix.length) is req.prefix
    return true

  # Do not otherwise replicate
  return false

# Attachments are loaded from provisioning-global/*
path = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'provisioning-global'))
