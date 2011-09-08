#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

config = require('ccnq3_config').config

zappa = require 'zappa'
zappa.run config.portal.port, config.portal.hostname, ->
  # Configuration
  config = require('ccnq3_config').config
  # Session store
  store = config.session_store

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
