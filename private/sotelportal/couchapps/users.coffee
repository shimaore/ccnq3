###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

# Install:
#   coffee -c users.coffee
#   couchapp push users.js http://127.0.0.1:5984/_users

couchapp = require('couchapp')

ddoc =
  _id: '_design/app'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

ddoc.filters.send_confirmation = (doc,req) ->
  return if doc.status is 'send_confirmation' then true else false

ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->


  if not oldDoc or oldDoc.status isnt 'confirmed'
    for role in newDoc.roles?
      do (role) ->
        if role.match('^account:')
          throw {forbidden : "Only registered users might be granted account access."}

# Attachments are loaded from users/*
# var path     = require('path');
# couchapp.loadAttachments(ddoc, path.join(__dirname, 'users'));
