###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/opensips'
  language: 'javascript'
  views: {}
  lists: {}
  shows: {}
  filters: {}
  updates: {}
  rewrites: []
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

ddoc.views.gateways_by_domain =
  map: p_fun (doc) ->

    if doc.type? and doc.type is 'gateway'
      emit doc.sip_domain_name, doc

    if doc.type? and doc.type is 'host' and doc.sip_profiles?
      for name, rec of doc.sip_profiles
        do (rec) ->
          # for now we only generate for egress gateways
          if rec.egress_gwid?
            ip = rec.egress_sip_ip ? rec.ingress_sip_ip
            port = rec.egress_sip_port ? rec.ingress_sip_port+10000
            emit doc.sip_domain_name,
              account: ""
              gwid: rec.egress_gwid
              address: ip+':'+port
              gwtype: 0
              probe_mode: 0
              strip: 0

    return

ddoc.views.rules_by_domain =
  map: p_fun (doc) ->
    if doc.type? and doc.type is 'rule'
      emit doc.sip_domain_name, doc
    return

ddoc.views.carriers_by_host =
  map: p_fun (doc) ->
    if doc.type? and doc.type is 'carrier'
      emit doc.host, doc
    return

## Registrant view and list

ddoc.views.registrant_by_host =
  map: p_fun (doc) ->

    if doc.type? and doc.type is 'number' and doc.registrant_password? and doc.registrant_host? and doc.registrant_remote_ipv4?
      value =
        registrar: "sip:#{doc.registrant_remote_ipv4}"
        # proxy: null
        aor: "sip:00#{doc.number}@#{doc.registrant_remote_ipv4}"
        # third_party_registrant: null
        username: "00#{doc.number}"
        password: doc.registrant_password
        # binding_URI: "sip:00#{doc.number}@#{p.interfaces.primary.ipv4 ? p.host}:5070"
        # binding_params: null
        expiry: doc.registrant_expiry ? 3600
        # forced_socket: null

      hosts = doc.registrant_host
      if typeof hosts is 'string'
        hosts = [hosts]

      for host in hosts
        value.binding_URI = "sip:00#{doc.number}@#{host}:5070"
        emit [host,1], value

    if doc.type? and doc.type is 'host' and doc.applications.indexOf('applications/registrant') >= 0
      # Make sure these records show up at the top
      emit [doc.host,0], interfaces:doc.interfaces

    return

ddoc.lists.registrant = p_fun (head,req) ->
  quote = require 'lib/quote'
  start {
    headers:
      'Content-Type': 'text/plain'
  }
  t = req.query.t
  c = req.query.c
  types = quote.column_types[t]
  columns = c.split ','
  send quote.first_line(types,columns)
  hosts = {}
  while row = getRow()
    do (row) ->
      host =row.key[0]
      if row.value.interfaces?
        hosts[host] = row.value
      else
        ipv4 = hosts[host]?.interfaces.primary?.ipv4
        if ipv4?
          row.value.binding_URI = row.value.binding_URI.replace host, ipv4
        send quote.value_line types, t, row.value, columns
  return # KeepMe!
