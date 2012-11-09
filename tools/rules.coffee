#!/usr/bin/env coffee
#
# This script will update a routing table (no time records)
# for the given parameters:
#     ./rules.coffee <sip_domain_name> <groupid>
# The input lines must contain semicolon-separated
#     prefix;gwlist;attrs

request = require 'request'
byline = require 'byline'
pico = require 'pico'
ccnq3 = require 'ccnq3'
stream = require 'stream'
qs = require 'querystring'

sip_domain_name = process.argv[2]
groupid = process.argv[3]

ccnq3.config (config) ->
  db_uri = config.provisioning.couchdb_uri
  db = pico.request db_uri

  existing_rule = {}
  new_ruleid = 0

  db.get '_design/update_rules', (e,r,b) ->
    if e then throw e
    if b.error then throw new Error b.error
    design =
      _id: '_design/update_rules'
      _rev: b._rev
      views:
        by_id:
          map: (doc) ->
            if doc.sip_domain_name? and doc.groupid?
              emit [doc.sip_domain_name,doc.groupid], null

    db.put design, (e,r,b) ->
      if e then throw e
      if b.error then throw new Error b.error

      view_key = qs.escape JSON.stringify [sip_domain_name,groupid]

      db.get '_design/update_rules/_view/by_id?key=#{view_key}"', json:true, (e,r,b) ->
        if e then throw e
        if b.error then throw new Error b.error
        for row in b.rows
          k = row.prefix
          existing_rule[k] = _rev:row.value._rev, ruleid:row.ruleid
          new_ruleid = row.ruleid if row.ruleid > new_ruleid
          do run

  post = db.post '_bulk_docs', json: true, (e,r,b) ->
    console.dir {e,b}
  emit_stream = new stream()
  emit_stream.pipe post

  run = ->
    columns = []
    input = byline process.stdin
    first_line = true
    input.on 'data', (line) ->
      if first_line
        emit_stream.emit 'data', '{"docs":['
      else
        [prefix,gwlist,attrs]= line.split /;/
        emit_rule {prefix,gwlist,attrs}

      first_line = false

    input.on 'end', ->
      for key, data of existing_rule
        emit_stream.emit 'data', JSON.stringify {_id:data.id,_rev:data._rev,_deleted:true}
      emit_stream.emit 'data', ']}'
      emit_stream.emit 'end'

  first_time = true
  emit_rule = (o) ->
    emit_stream.emit 'data', ",\n" unless first_time
    first_time = false

    type = 'rule'
    prefix = o.prefix
    if existing_rule[prefix]?
      console.log "Updating rule for prefix #{prefix}"
      {_rev,ruleid} = existing_rule[k]
    else
      console.log "Creating rule for prefix #{prefix}"
      ruleid = new_ruleid++
      _rev = null

    rule = [sip_domain_name,ruleid].join ':'
    _id = [type,rule].join ':'

    emit_stream.emit 'data', JSON.stringify {

      _id
      _rev
      type
      rule
      sip_domain_name
      ruleid

      groupid
      prefix

      gwlist: o.gwlist
      attrs: o.attrs

    }
    delete existing_rule[k]
