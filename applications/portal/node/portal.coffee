#!/usr/bin/env zappa
###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

app "portal", (server) ->
  express = require('express')
  # server.use express.static("#{process.cwd()}/public")
  # server.use express.favicon()
  server.use express.logger()
  server.use express.bodyParser()
  server.use express.cookieParser()
  server.use express.session(secret: "a"+Math.random())
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

# This gets everything started.
client main: ->
  $(document).ready ->
    default_scripts = [
        '/public/javascripts/jquery',
        '/public/javascripts/jquery-ui',
        '/public/javascripts/jquery.validate',
        '/u/content'
    ]
    for s in default_scripts
      $.getScript s + '.js'

include 'content.coffee'
include 'login.coffee'
include 'register.coffee'
include 'confirm.coffee'
include 'profile.coffee'
include 'changes.coffee'
