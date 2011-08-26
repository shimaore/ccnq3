#!/usr/bin/env zappa
###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

app "portal", (server) ->
  # Configuration
  config = require('ccnq3_config').config
  # Session store
  express = require('express')
  CouchDBStore = require('connect-couchdb')(express)
  store = new RedisStore(config.session.couchdb_store)

  server.use express.logger()
  server.use express.bodyParser()
  server.use express.cookieParser()
  server.use express.session( secret: config.session.secret, store: store )
  server.use express.methodOverride()

#
# Configuration
#

config = require('ccnq3_config').config

def config: config

def cdb: require 'cdb'

#
# Special rendering helpers
#

# This gets everything started.
client main: ->
  $(document).ready ->
    default_scripts = [
        '/public/js/jquery-ui',
        '/public/js/jquery.validate',
        '/u/content'
    ]
    for s in default_scripts
      $.getScript s + '.js'

include 'content.coffee'
include 'login.coffee'
include 'register.coffee'
include 'recover.coffee'
include 'profile.coffee'
