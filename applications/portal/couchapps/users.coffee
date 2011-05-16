###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

# Install:
#   coffee -c users.coffee
#   couchapp push users.js http://127.0.0.1:5984/_users

couchapp = require('couchapp')

ddoc =
  _id: '_design/portal'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

ddoc.filters.send_confirmation = (doc,req) ->
  return doc.status is 'send_confirmation'

ddoc.filters.send_password = (doc,req) ->
  return doc.send_password? and doc.send_password

ddoc.filters.confirmed = (doc,req) ->
  return doc.status is 'confirmed'

# Attachments are loaded from users/*
# var path     = require('path');
# couchapp.loadAttachments(ddoc, path.join(__dirname, 'users'));
