###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/opensips'
  language: 'javascript'
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

ddoc.shows.format = p_fun (doc,req) ->
  quote = require 'lib/quote'
  body = ''
  if doc?
    t = req.query.t
    c = req.query.c
    types = quote.column_types[t]
    columns = c.split ','
    body = quote.first_line(types,columns) + quote.value_line(types,t,doc,columns)
  return {
    headers:
      'Content-Type': 'text/plain'
    body:
      body
  }

ddoc.lists.format = p_fun (head,req) ->
  quote = require 'lib/quote'
  start {
    headers:
      'Content-Type': 'text/plain'
  }
  if not head.total_rows
    send ''
    return
  t = req.query.t
  c = req.query.c
  types = quote.column_types[t]
  columns = c.split ','
  send quote.first_line(types,columns)
  while row = getRow()
    do (row) ->
      send quote.value_line types, t, row.value, columns
  return # KeepMe!

ddoc.views.gateways_by_host =
  map: p_fun (doc) ->

    if doc.type? and doc.type is 'gateway'
      emit doc.host, doc

    if doc.type? and doc.type is 'host' and doc.sip_profiles?
      for name, rec of doc.sip_profiles
        do (rec) ->
          # for now we only generate for egress gateways
          if rec.egress_gwid?
            ip = rec.egress_sip_ip ? rec.ingress_sip_ip
            port = rec.egress_sip_port ? rec.ingress_sip_port+10000
            emit doc.host,
              account: ""
              host: doc.host
              gwid: rec.egress_gwid
              address: ip+':'+port
              gwtype: 0
              probe_mode: 0
              strip: 0

    return

ddoc.views.rules_by_host =
  map: p_fun (doc) ->
    if doc.type? and doc.type is 'rule'
      emit doc.host, doc
    return

# For completeness, not planning to use them at this time.
ddoc.views.gwlists_by_host =
  map: p_fun (doc) ->
    if doc.type? and doc.type is 'gw_list'
      emit doc.host, doc
    return
