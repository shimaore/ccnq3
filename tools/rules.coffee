#!/usr/bin/env coffee
#
# This script will update a routing table (no time records)
# for the given parameters:
#     ./rules.coffee <sip_domain_name> <groupid>
# The input lines must contain semicolon-separated
#     prefix;gwlist;attrs

byline = require 'byline'
pico = require 'pico'
ccnq3 = require 'ccnq3'
stream = require 'stream'
qs = require 'querystring'
fun = (f) -> '('+f+')'

debug = false

sip_domain_name = process.argv[2]
groupid = parseInt process.argv[3]

console.log "Started for sip_domain_name #{sip_domain_name} groupid #{groupid}"

class Bulk
  constructor: (@db) ->
    @line = 0
    @stream = null
    @blocks = 0
    @queue = []

  submit: (cb) ->
    @stream.emit 'data', ']}'
    @line = 0
    @finally = cb
    @stream.emit 'end'
    @stream = null
    return

  emit: (l,cb) ->
    # Enqueue the data
    if l?
      @queue.push l
    # Wait until the current submission is over to submit a new one
    if @finally
      return
    # Start of a new bulk block
    if @line is 0
      @blocks++
      block = @blocks
      console.log "Starting block #{@blocks}." if debug
      post = @db.post '_bulk_docs', json: true
      post.on 'end', (e) =>
        if e
          console.dir error:e, when:'bulk docs'
          return
        console.log "Submitted block #{block} (queue depth: #{@queue.length})."
        the_cb = @finally
        delete @finally
        do the_cb
        return
      @stream = new stream()
      @stream.pipe post

      post.pipe process.stdout

      @stream.emit 'data', '{"docs":[\n'

    # Flush the queue
    while @queue.length
      @stream.emit 'data', ",\n" if @line isnt 0
      @stream.emit 'data', JSON.stringify @queue.shift()
      @line++

    # End of bulk block
    if @line >= 10000 or not l?
      @submit cb
    else
      do cb
    return

ccnq3.config (config) ->
  db_uri = config.provisioning.couchdb_uri
  db = pico.request db_uri

  bulk = new Bulk db

  # A prefix-to-{_rev,rule} mapping
  existing_rule = {}

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
              emit [doc.sip_domain_name,parseInt doc.groupid], rev:doc._rev, rule:doc.rule, prefix:doc.prefix

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
          console.dir error:b, when:'get view by_id'
          return
        for row in b.rows
          existing_rule[row.value.prefix] = _rev:row.value.rev, rule:row.value.rule
        console.log "Ruleset had #{b.rows.length} rules."

        do run
        return

  run = ->
    columns = []
    process.stdin.setEncoding 'utf8'
    input = byline process.stdin
    n = 0
    input.on 'data', (line) ->
      [prefix,gwlist,attrs] = line.split /;/
      n++
      input.pause()
      emit_rule {prefix,gwlist,attrs}, ->
        input.resume()
      return

    input.on 'end', ->
      console.log "End of input stream"
      d = 0
      keys = []
      for key of existing_rule
        keys[d] = key
        d++
      console.log "Starting to delete #{d} old rules."
      q = 0
      purge = ->
        if d is 0
          bulk.emit null, ->
            console.log "Requested: add or update #{n} rules, delete #{q} old rules."
        else
          d--
          key = keys[d]
          data = existing_rule[key]
          type = 'rule'
          _id = [type,data.rule].join ':'
          q++
          bulk.emit {_id,_rev:data._rev,_deleted:true}, purge
      do purge
      return

  emit_rule = (o,cb) ->
    type = 'rule'
    prefix = o.prefix
    if existing_rule[prefix]?
      console.log "Updating rule for prefix #{prefix}" if debug
      {_rev,rule} = existing_rule[prefix]
    else
      console.log "Creating rule for prefix #{prefix}" if debug
      rule = [sip_domain_name,groupid,prefix].join ':'

    _id = [type,rule].join ':'

    delete existing_rule[prefix]
    bulk.emit {

      _id
      _rev
      type
      rule
      sip_domain_name

      groupid
      prefix

      gwlist: o.gwlist
      attrs: o.attrs

    }, cb
    return
