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

    # Replace loc_db with e.g. redis-store
    loc_db = cdb.new config.provisioning.couchdb_uri

    def db: db
    def loc_db: loc_db

    use 'bodyParser', 'logger'

    def config: config

    def line: (a) ->
      a.join("\t") + "\n"

    # Typical:
    #   GET /domain/?k=domain&v=${requested_domain}&c=domain

    get '/domain/': ->
      if config.opensips_proxy.domains[@v]?
        return line(["string"]) + line([@v])
      else
        return ""

    get '/subscriber/': -> # auth_table

    get '/location/': -> # usrloc_table
      if @k is 'username' and @c is 'username'
        loc_db.get "endpoint:#{@v}", (p) ->
          if p.error
            return send ""
          return send line(["string"]) + line([@v])
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

      return line(["int"]) + line([versions[@v]])
