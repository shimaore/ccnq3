#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

config = require('ccnq3_config').config

zappa = require 'zappa'
zappa.run config.portal.port, config.portal.hostname, ->
  # Configuration
  ccnq3_config = require 'ccnq3_config'
  config = ccnq3_config.config
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

  include 'login.coffee'
  include 'register.coffee'
  include 'recover.coffee'
  include 'profile.coffee'
