###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/opensips'
  views: {}
  lists: {} # http://guide.couchdb.org/draft/transforming.html
  shows: {} # http://guide.couchdb.org/draft/show.html
  filters: {} # used by _changes
  rewrites: [] # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
  lib: {}

fs = require 'fs'
coffee = require 'coffee-script'

module.exports = ddoc

ddoc.lib.quote =  coffee.compile fs.readFileSync './quote.coffee'

ddoc.shows.format = (doc,req) ->
  quote = require 'lib/quote'
  return {
    headers:
      'Content-Type': 'text/plain'
    body:
      quote.from_hash req.query.t, doc, req.query.c
  }

ddoc.lists.format = (head,req) ->
  quote = require 'lib/quote'
  start {
    headers:
      'Content-Type': 'text/plain'
  }
  while row = getRow()
    value = quote.from_hash req.query.t, row.value, req.query.c
    send value
  return # KeepMe!

ddoc.views.gateways_by_host = (doc) ->
  if doc.type is 'gateway'
    emit doc.host, null
  return

ddoc.views.rules_by_host = (doc) ->
  if doc.type is 'rule'
    emit doc.host, null
  return

# For completeness, not planning to use them at this time.
ddoc.views.gwlists_by_host = (doc) ->
  if doc.type is 'gw_list'
    emit doc.host, null
  return
