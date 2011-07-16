###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

couchapp = require('couchapp')
path     = require('path')

ddoc = {
    _id: '_design/html'
  , views: {}
  , lists: {} # http://guide.couchdb.org/draft/transforming.html
  , shows: {} # http://guide.couchdb.org/draft/show.html
  , filters: {} # used by _changes
  , rewrites: [] # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
}

module.exports = ddoc

ddoc.rewrites.push
  from: '/'
  to:   'index.html'
ddoc.rewrites.push
  from: '/public/*'
  to:   '../public/*'
ddoc.rewrites.push
  from: '/*'
  to:   '*'

couchapp.loadAttachments(ddoc, path.join(__dirname))
