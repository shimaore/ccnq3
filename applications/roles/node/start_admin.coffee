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
  CouchDBStore = require('connect-couchdb')(express)
  store = new CouchDBStore(config.session.couchdb_store)

  use 'logger', 'bodyParser', 'cookieParser', 'methodOverride',
    session: { secret: config.session.secret, store: store  }

  include 'admin'
  include 'login'
  include 'replicate'
