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
fun = (f) -> '('+f+')'

sip_domain_name = process.argv[2]
groupid = process.argv[3]

console.log "Started for sip_domain_name #{sip_domain_name} groupid #{groupid}"

ccnq3.config (config) ->
  db_uri = config.provisioning.couchdb_uri
  db = pico.request db_uri

  existing_rule = {}
  new_ruleid = 0

  db.get '_design/update_rules', json:true, (e,r,b) ->
    if e
      console.dir error:e, when:'get update_rules'
      return
    design =
      _id: '_design/update_rules'
      _rev: b._rev
      views:
        by_id:
          map: fun (doc) ->
            if doc.sip_domain_name? and doc.groupid?
              emit [doc.sip_domain_name,doc.groupid], rev:doc._rev, ruleid:doc.ruleid, prefix:doc.prefix

    db.put '_design/update_rules', json:design, (e,r,b) ->
      if e
        console.dir error:e, when:'put update_rules'
        return
      if b.error or not b.ok
        console.dir error:b, when:'put update_rules'
        return

      view_key = qs.escape JSON.stringify [sip_domain_name,groupid]

      db.get "_design/update_rules/_view/by_id?key=#{view_key}", json:true, (e,r,b) ->
        if e
          console.dir error:e, when:'get view by_id'
          return
        if b.error
          console.dir error:b, when:'put update_rules'
          return
        for row in b.rows
          existing_rule[row.value.prefix] = _rev:row.value.rev, ruleid:row.value.ruleid
          new_ruleid = row.value.ruleid if row.value.ruleid > new_ruleid
        console.log "Ruleset had #{b.rows.length} rules."
        do run

  post = db.post '_bulk_docs', json: true, (e,r,b) ->
    if e
      console.dir error:e, when:'bulk docs'
      return
    console.log "Pushed #{b.length ? 'no'} rows."
  emit_stream = new stream()
  emit_stream.pipe post

  run = ->
    columns = []
    input = byline process.stdin
    n = 0
    input.on 'data', (line) ->
      if n is 0
        emit_stream.emit 'data', '{"docs":['

      [prefix,gwlist,attrs]= line.split /;/
      emit_rule {prefix,gwlist,attrs}

      n++

    input.on 'end', ->
      d = 0
      for key, data of existing_rule
        emit_stream.emit 'data', JSON.stringify {_id:data.id,_rev:data._rev,_deleted:true}
        d++
      emit_stream.emit 'data', ']}'
      emit_stream.emit 'end'
      console.log "Requested: add or update #{n} rules, delete #{d} old rules."

  first_time = true
  emit_rule = (o) ->
    emit_stream.emit 'data', ",\n" unless first_time
    first_time = false

    type = 'rule'
    prefix = o.prefix
    if existing_rule[prefix]?
      console.log "Updating rule for prefix #{prefix}"
      {_rev,ruleid} = existing_rule[prefix]
    else
      console.log "Creating rule for prefix #{prefix}"
      ruleid = ++new_ruleid

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
    delete existing_rule[prefix]
