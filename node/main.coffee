#!/usr/bin/env zappa
###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

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
