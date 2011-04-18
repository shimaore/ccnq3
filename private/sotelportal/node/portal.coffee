#!/usr/bin/env zappa
###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

app "portal", (server) ->
  express = require('express')
  server.use express.staticProvider("#{process.cwd()}/public")
  server.use express.favicon()
  server.use express.logger()
  server.use express.bodyDecoder()
  server.use express.cookieDecoder()
  server.use express.session(secret: Math.random())
  server.use express.methodOverride()

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

client main: ->
  $(document).ready ->
    $.getScript('register.js')

include 'register.coffee'
