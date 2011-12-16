###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

# Use this couchapp if you need to have the public subdirectories in your CouchDB.

couchapp = require('couchapp')
path     = require('path')

p_fun = (f) -> '('+f+')'

ddoc = {
    _id: '_design/public'
  , views: {}
  , lists: {} # http://guide.couchdb.org/draft/transforming.html
  , shows: {} # http://guide.couchdb.org/draft/show.html
  , filters: {} # used by _changes
  , rewrites: {} # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
}

module.exports = ddoc

ddoc.filters.hostname = p_fun (doc,req) ->
  return doc.type is 'host' and doc.host is req.query.hostname

couchapp.loadAttachments(ddoc, path.join(__dirname))
