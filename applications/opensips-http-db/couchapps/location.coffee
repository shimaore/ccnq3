###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/location'
  language: 'javascript'
  views: {}
  lists: {} # http://guide.couchdb.org/draft/transforming.html
  shows: {} # http://guide.couchdb.org/draft/show.html
  filters: {} # used by _changes
  rewrites: [] # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
  lib: {}

module.exports = ddoc

# Too bad we can't use _all_docs with a list.
ddoc.views.all =
  map: (doc) ->
    if doc.callid?
      emit null, doc
