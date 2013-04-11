#!/usr/bin/env coffee
# This script:
#   nice sudo -u ccnq3 ./delete-rules.coffee <sip_domain_name> <groupid>
# Get a view at the first rule:
#   curl 'http://127.0.0.1:5984/provisioning/_all_docs?start_key="rule"&limit=1'

pico = require 'pico'
ccnq3 = require 'ccnq3'
qs = require 'querystring'
k = (t) -> qs.escape JSON.stringify t

sip_domain_name = process.argv[2]
groupid = parseInt process.argv[3]
batch_size = 2000

console.log "Started for sip_domain_name #{sip_domain_name} groupid #{groupid}"

ccnq3.config (config) ->
  db_uri = config.provisioning.local_couchdb_uri
  db = pico.request db_uri

  key = "rule:#{sip_domain_name}:#{groupid}"

  purge = ->
    db.get "_all_docs?start_key=#{k key+':'}&end_key=#{k key+';'}&limit=#{batch_size}", json:true, (e,r,b) ->
      if e
        console.dir error:e, when:'get docs'
        return
      if b.error
        console.dir error:b, when:'get docs'
        return
      o = []
      for row in b.rows
        o.push {_id:row.id,_rev:row.value.rev,_deleted:true}
      if o.length is 0
        return
      console.log "Deleting #{o.length} rules"
      db.post '_bulk_docs', json: {docs:o}, (e,r,b) ->
        if e
          console.dir error:e, when:'post bulk_docs'
        do purge

  do purge
