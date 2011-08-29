###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###


couchapp = require('couchapp')
path     = require('path')

ddoc = {
    _id: '_design/commands'
  , views: {}
  , lists: {} # http://guide.couchdb.org/draft/transforming.html
  , shows: {} # http://guide.couchdb.org/draft/show.html
  , filters: {} # used by _changes
  , rewrites: {} # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
}

module.exports = ddoc

ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->

  user_is = (role) ->
    userCtx.roles?.indexOf(role) >= 0

  if not user_is('commands_writer') or not user_is('_admin')
    throw forbidden:'Not authorized to write in this database.'

ddoc.filters.hostname = (doc,req) ->
  return doc.host? is req.query.hostname
