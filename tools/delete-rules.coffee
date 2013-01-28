#!/usr/bin/env coffee
#
# This script will update a routing table (no time records)
# for the given parameters:
#     ./rules.coffee <sip_domain_name> <groupid>
# The input lines must contain semicolon-separated
#     prefix;gwlist;attrs

pico = require 'pico'
ccnq3 = require 'ccnq3'
qs = require 'querystring'
fun = (f) -> '('+f+')'

debug = true

sip_domain_name = process.argv[2]
groupid = parseInt process.argv[3]
batch_size = 10000

console.log "Started for sip_domain_name #{sip_domain_name} groupid #{groupid}"

ccnq3.config (config) ->
  db_uri = config.provisioning.couchdb_uri
  db = pico.request db_uri

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
            if doc.sip_domain_name? and doc.groupid? and not doc._deleted
              emit [doc.sip_domain_name,parseInt doc.groupid], rev:doc._rev, ruleid:doc.ruleid, prefix:doc.prefix

    db.put '_design/update_rules', json:design, (e,r,b) ->
      if e
        console.dir error:e, when:'put update_rules'
        return
      if b.error or not b.ok
        console.dir error:b, when:'put update_rules'
        return

      view_key = qs.escape JSON.stringify [sip_domain_name,groupid]

      purge = ->
        db.get "_design/update_rules/_view/by_id?key=#{view_key}&limit=#{batch_size}", json:true, (e,r,b) ->
          if e
            console.dir error:e, when:'get view by_id'
            return
          if b.error
            console.dir error:b, when:'put update_rules'
            return
          o = []
          for row in b.rows
            # console.dir row
            o.push {_id:row.id,_rev:row.value.rev,_deleted:true}
          if o.length is 0
            return
          console.log "Deleting #{o.length} rules\n"
          db.post '_bulk_docs', json: {docs:o}, (e,r,b) ->
            # console.log require('util').inspect arguments, false, 3
            if e
              console.dir error:e, when:'post bulk_docs'
            do purge 

      do purge
