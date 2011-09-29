#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

require('ccnq3_config').get (config)->

  zappa = require 'zappa'
  zappa.run config.opensips_proxy.port, config.opensips_proxy.hostname, {config}, ->

    cdb = require 'cdb'
    db = cdb.new config.provisioning.couchdb_uri

    loc_db = cdb.new config.opensips_proxy.usrloc_uri

    def db: db
    def loc_db: loc_db

    # db_dbase.c lists: int, double, string, str, blob, date; str and blob are equivalent for this interface.
    column_types =
      usrloc:
        username: 'string'
        domain: 'string'
        contact: 'string'
        received: 'string'
        path: 'string'
        expires: 'date'
        q: 'double'
        callid: 'string'
        cseq: 'int'
        last_modified: 'date'
        flags: 'int'
        cflags: 'int'
        user_agent: 'string'
        socket: 'string'
        methods: 'int'
      version:
        table_name: 'string'
        table_version: 'int'

    use 'bodyParser', 'logger'

    def config: config

    line = (a) ->
      quote_delimiter = '"'
      field_delimiter = "\t"
      row_delimiter = "\n"
      [ (s+'').replace quote_delimiter, quote_delimiter+quote_delimiter for s in a ].join(field_delimiter) + row_delimiter

    first_line = (table,c)->
      return line [ column_types[table][col] for col in c.split ',' ]

    value_line = (hash,c)->
      return line [ (hash[col] or '') for col in c.split ',' ]

    def from_array: (n,t,c) ->
      if not t? or t.length is 0 then return send ""
      send first_line (n,c) + [ value_line(l,c) for l in t ].join('')

    def from_hash: (n,h,c) ->
      send first_line(n,c) + value_line(h,c)

    # Typical:
    #   GET /domain/?k=domain&v=${requested_domain}&c=domain

    get '/domain/': ->
      if config.opensips_proxy.domains[@v]?
        return line(["string"]) + line([@v])
      else
        return ""

    get '/subscriber/': -> # auth_table
      send ""
      return

    get '/location/': -> # usrloc_table

      if @k is 'username'
        loc_db.get @v, (p) =>
          if p.error then return send ""
          from_hash 'usrloc', p, @c

      if not @k?
        # Rewrite-me: will load everything in memory and build the reply in memory.
        # Instead use a CouchDB "list"
        #   loc_db.req "_design/http_db/_list/usrloc/_all_docs"
        # and figure out how to stream the response through Zappa.
        loc_db.req {uri:'_all_docs?include_docs=true'}, (t) =>
          from_array 'usrloc', t.rows, @c

      return

    post '/location/': ->

    get '/avpops/': ->


    get '/dr_gateways/': ->
      if not @k?
        # For now assume the gateways for a given host are stored in that host's configuration record.
        from_array 'dr_gateways', config.gateways, @c

    get '/dr_rules/': ->

    get '/dr_groups/': ->

    get '/dr_gw_lists/': ->

    get '/version/': ->
      return unless @k is 'table_name' and @c is 'table_version'

      # Versions for OpenSIPS 1.7.0
      versions =
        location: 1006
        subscriber: 7
        dr_gateways: 4
        dr_rules: 3

      return from_hash 'version', {table_version:versions[@v]}, @c
