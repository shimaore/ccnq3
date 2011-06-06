###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

couchapp = require('couchapp')

ddoc =
  _id: '_design/roles'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->

  required = (field, message) ->
    if not newDoc[field]
      throw {forbidden : message || "Document must have a " + field}

  unchanged = (field) ->
    if oldDoc and toJSON(oldDoc[field]) is toJSON(newDoc[field])
      throw {forbidden : "Field can't be changed: " + field}

  if not user_is('_admin') and not user_is('databases-writer')
    throw {forbidden : "Not authorized to make modifications."}

  # Handle delete documents.
  if newDoc._deleted is true

    if oldDoc.do_not_delete
      throw {forbidden: 'Database is tagged as do_not_delete.'}

    return
  else
    # Document was not deleted, any tests here?

  # Basically you can add any other field, etc, just don't touch these.
  required('uuid')
  unchanged('uuid')
  required('source')
  unchanged('source')
  required('prefix')
  unchanged('prefix')


# Attachments are loaded from users/*
# var path     = require('path');
# couchapp.loadAttachments(ddoc, path.join(__dirname, 'databases'));
