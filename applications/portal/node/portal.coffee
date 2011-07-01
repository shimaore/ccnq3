#!/usr/bin/env zappa
###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

app "portal", (server) ->
  # Configuration
  fs = require 'fs'
  config_location = process.env.npm_package_config_config_file
  config = JSON.parse(fs.readFileSync(config_location, 'utf8'))
  # Session store
  express = require('express')
  if config.session.memcached_store?
    MemcachedStore = require 'connect-memcached'
    store = new MemcachedStore(config.session.memcached_store)
  if config.session.redis_store?
    RedisStore = require('connect-redis')(express)
    store = new RedisStore(config.session.redis_store)

  server.use express.logger()
  server.use express.bodyParser()
  server.use express.cookieParser()
  server.use express.session secret: config.session.secret, store: store
  server.use express.methodOverride()

#
# Configuration
#

fs = require 'fs'
config_location = process.env.npm_package_config_config_file
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def config: config

def cdb: require 'cdb'

#
# Special rendering helpers
#

# Default layout is to render a widget
layout ->
  html -> @content

helper widget: (t) ->
  @session = session
  render t #, layout: 'widget'

helper error: (m) ->
  @error = m
  render 'error'

view 'error': ->
  div class: 'error', -> 'An errror occurred. Please try again.'
  div class: 'info', -> @error

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
include 'confirm.coffee'
include 'recover.coffee'
include 'profile.coffee'
# include 'changes.coffee' # not needed if jquery.cdbcc.js works
