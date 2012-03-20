###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

# This usercode module is used especially the host systems who might replicate
# from the main database (using their personalized logins), to retrieve their
# own "host" record.

p_fun = (f) -> '('+f+')'

ddoc = {
    _id: '_design/host'
  , views: {}
  , lists: {} # http://guide.couchdb.org/draft/transforming.html
  , shows: {} # http://guide.couchdb.org/draft/show.html
  , filters: {} # used by _changes
  , rewrites: [] # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
}

module.exports = ddoc

ddoc.views.traces_hosts =
  map: p_fun (doc) ->
    if doc.type is 'host' and doc.applications?.indexOf('applications/traces') >= 0 and doc.traces?.interfaces?
      emit doc.host, null

ddoc.filters.hostname = p_fun (doc,req) ->
  return doc.type is 'host' and doc.host is req.query.hostname

# Attachments (user couchapp)
couchapp = require 'couchapp'
path     = require 'path'
couchapp.loadAttachments ddoc, path.join(__dirname, 'usercode')
