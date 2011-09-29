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

    def column_types:
      usrloc:
        username: 'string'
        domain: 'string'
        contact: 'string'
        received: 'string'
        path: 'string'
        expires: 'string' # datetime
        q: 'float'
        callid: 'string'
        cseq: 'int'
        last_modified: 'string' # datetime
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

    def line: (a) ->
      a.join("\t") + "\n"

    def first_line: (table,c)->
      return line( column_types[table][col] for col in c.split ',' )

    def value_line: (hash,c)->
      return line( hash[col] for col in c.split ',' )

    # Typical:
    #   GET /domain/?k=domain&v=${requested_domain}&c=domain

    get '/domain/': ->
      if config.opensips_proxy.domains[@v]?
        return line(["string"]) + line([@v])
      else
        return ""

    get '/subscriber/': -> # auth_table

    get '/location/': -> # usrloc_table
      if @k is 'username'
        loc_db.get @v, (p) ->
          if p.error
            return send ""
          return send first_line('usrloc',@c) + value_line(p,@c)
      if not @k?
        # Rewrite-me: will load everything in memory and build the reply in memory.
        # Instead use a CouchDB "list"
        #   loc_db.req "_design/http_db/_list/usrloc/_all_docs"
        # and figure out how to stream the response through Zappa.
        loc_db.req {uri:'_all_docs?include_docs=true'}, (t) ->
          return first_line('usrloc',@c) +
                 join( value_line(l,@c) for l in t.docs )
      return

    post '/location/': ->

    get '/avpops/': ->


    get '/dr_gateways/': ->

    get '/dr_rules/': ->

    get '/dr_groups/': ->

    get '/dr_gw_lists/': ->

    get '/version/': ->
      return unless @k is 'table_name' and @c is 'table_version'

      # Versions for OpenSIPS 1.7.0
      versions =
        location: 1006
        subscriber: 7

      return first_line('version',@c) + value_line({table_version:versions[@v]},@c)
