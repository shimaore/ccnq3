#!/usr/bin/env zappa
###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

app "default", (server) ->
  express = require('express')
  server.use express.staticProvider("#{process.cwd()}/public")
  server.use express.favicon()
  server.use express.logger()
  server.use express.bodyDecoder()
  server.use express.cookieDecoder()
  server.use express.session(secret: Math.random())
  server.use express.methodOverride()

include 'server.coffee'
include 'layouts.coffee'

#
# Special rendering helpers
#

helper page: (t,o) ->
  @session = session
  render t, o

helper widget: (t) ->
  @session = session
  render t, layout: 'widget'

helper error: (m) ->
  @error = m
  render 'error'

include 'register.coffee'
