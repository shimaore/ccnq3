###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc = {
    _id: '_design/host'
  , views: {}
  , lists: {} # http://guide.couchdb.org/draft/transforming.html
  , shows: {} # http://guide.couchdb.org/draft/show.html
  , filters: {} # used by _changes
  , rewrites: {} # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
}

module.exports = ddoc

ddoc.filters.hostname = p_fun (doc,req) ->
  return doc.type is 'host' and doc.host is req.query.hostname

ddoc.filters.replication = p_fun (doc,req) ->
  # Only replicate provisioning documents.
  if not doc.type?
    return false
  if doc._id.match /^_design/
    return false
  return true
