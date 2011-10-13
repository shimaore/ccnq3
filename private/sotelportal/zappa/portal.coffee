#!/usr/bin/env coffee
###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

require('ccnq3_config').get (config)->

  zappa = require 'zappa'
  zappa.run config.sotel_portal.port, config.sotel_portal.hostname, {config}, ->

      # Session store
      express = require 'express'
      if config.session?.memcached_store
        MemcachedStore = require 'connect-memcached'
        store = new MemcachedStore config.session.memcached_store
      if config.session?.redis_store
        RedisStore = require('connect-redis')(express)
        store = new RedisStore config.session.redis_store
      if config.session?.couchdb_store
        CouchDBStore = require('connect-couchdb')(express)
        store = new CouchDBStore config.sessions.couchdb_store
      if not store
        throw error:"No session store is configured in #{config_location}."

      use 'logger'
      , 'bodyParser'
      , 'cookieParser'
      , session: { secret: config.session.secret, store: store }
      , 'methodOverride'

      def config: config

      def cdb: require 'cdb'

      # Let Zappa serve it owns versions.
      enable 'serve jquery', 'serve sammy'

      # applications/portal
      portal_modules = ['login','profile','recover','register']
      include __dirname + "/../node_modules/ccnq3_portal/zappa/#{name}.coffee" for name in portal_modules

      # applications/roles
      roles_modules = ['login','admin','replicate']
      include __dirname + "/../node_modules/ccnq3_roles/zappa/#{name}.coffee" for name in roles_modules

      # This gets everything started.
      coffee '/p/main.js': ->
        $(document).ready ->
          default_scripts = [
              '/public/js/jquery-ui',
              '/public/js/jquery.validate'
              '/public/js/jquery.couch'
              '/public/js/jquery.deepjson'
              '/public/js/sammy'
              '/public/js/sammy.title'
              '/public/js/sammy.couch'
              '/public/js/coffeekup'
              '/public/js/forms'
              '/public/js/jquery.smartWizard-2.0'
              '/p/content'
          ]
          for s in default_scripts
            cb = $.getScript s + '.js', cb
          cb()

      include 'content.coffee'
      include 'login.coffee'

      include 'actions/default.coffee'
      include 'actions/sip_signup.coffee'
      # include 'actions/partner_signup.coffee'
