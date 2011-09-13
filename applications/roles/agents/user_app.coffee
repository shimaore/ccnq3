###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

# This couchapp is automatically inserted in a user database
# by the track_users agent.

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
ddoc.validate_doc_update = (newDoc, oldDoc) ->

  provisioning_types = ["number","endpoint","location","host"]

  if newDoc._id is "_design/userapp"
    throw {forbidden:'The user application should not be replicated here.'}

  required = (field, message) ->
    if not newDoc[field]
      throw {forbidden : message || "Document must have a " + field}

  unchanged = (field) ->
    if oldDoc and toJSON(oldDoc[field]) is toJSON(newDoc[field])
      throw {forbidden : "Field can't be changed: " + field}

  # Handle delete documents.
  if newDoc._deleted is true

    if oldDoc.do_not_delete
      throw {forbidden: 'Document is tagged as do_not_delete.'}

    # No further processing is required on deleted documents.
    return
  else
    # Document was not deleted, any tests here?

  # Validate the document's type
  required("type")
  unchanged("type")
  type = newDoc.type

  # This code only handles provisioning types.
  if not type in provisioning_types
    return

  required("account")

  # Each document of type T should have a .T record.
  required(type)
  unchanged(type)
  if newDoc._id isnt type+":"+newDoc[type]
    throw {forbidden: "Document ID must be #{type}:#{newDoc[type]}."}

  # Validate updates
  # if oldDoc

  # Validate create
  # if not oldDoc

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



# Attachments are loaded from provisioning-global/*
# path = require('path')
# couchapp.loadAttachments(ddoc, path.join(__dirname, 'provisioning-global'))
