#!/usr/bin/env coffee
###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

require('ccnq3_config').get (config)->

  zappa = require 'zappa'
  zappa.run config.portal.port, config.portal.hostname, ->

      # Session store
      if config.session?.memcached_store
        MemcachedStore = require 'connect-memcached'
        store = new MemcachedStore config.session.memcached_store
      if config.session?.redis_store
        RedisStore = require('connect-redis')(@express)
        store = new RedisStore config.session.redis_store
      if config.session?.couchdb_store
        CouchDBStore = require('connect-couchdb')(@express)
        store = new CouchDBStore config.sessions.couchdb_store
      if not store
        console.dir error:"No session store is configured. Zappa will leak memory."

      @use 'logger'
      , 'bodyParser'
      , 'cookieParser'
      , session: { secret: config.session.secret, store: store }
      , 'methodOverride'

      # applications/portal
      portal_modules = ['login','profile','recover','register']
      @include "./#{name}.coffee" for name in portal_modules

      # applications/roles
      roles_modules = ['login','replicate'] # 'admin', -- not ready
      @include "../node_modules/ccnq3_roles/zappa/#{name}.coffee" for name in roles_modules

      @include './content.coffee'
