#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

require('ccnq3_config').get (config)->

  zappa = require 'zappa'
  zappa.run config.opensips_proxy.port, config.opensips_proxy.hostname, {config}, ->


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

    post '/location/': ->

    get '/avpops/': ->


    get '/dr_gateways/': ->

    get '/dr_rules/': ->

    get '/dr_groups/': ->

    get '/dr_gw_lists/': ->
