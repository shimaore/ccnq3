#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

zappa = require 'zappa'
config = require('ccnq3_config').config

zappa config.roles.port, config.roles.hostname, ->

  config = require('ccnq3_config').config
  def config: config

  # Session store
  express = require('express')
  if config.session?.memcached_store
    MemcachedStore = require 'connect-memcached'
    store = new MemcachedStore(config.session.memcached_store)
  if config.session?.redis_store
    RedisStore = require('connect-redis')(express)
    store = new RedisStore(config.session.redis_store)

  use 'logger', 'bodyParser', 'cookieParser', 'methodOverride'
  use session: { secret: config.session?.secret, store: store  }

  include 'admin'
  include 'login'
  include 'replicate'
