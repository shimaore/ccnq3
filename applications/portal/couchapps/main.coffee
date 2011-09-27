###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/portal'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

ddoc.filters.send_password = (doc,req) ->
  return doc.send_password? and doc.send_password
