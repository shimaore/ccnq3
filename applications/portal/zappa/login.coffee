###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  pico = require 'pico'
  url = require 'url'
  querystring = require 'querystring'

  config = null
  require('ccnq3_config') (c) ->
    config = c

  @post '/ccnq3/portal/login.json': ->
    username = @request.param 'username'
    if not username?
      return @send error:'Missing username'
    password = @request.param 'password'
    if not password?
      return @send error:'Missing password'

    uri = url.parse config.session.couchdb_uri
    uri.auth = "#{querystring.escape username}:#{querystring.escape password}"
    delete uri.href
    delete uri.host
    session_db = pico url.format uri
    session_db.request.get jar:false, json:true, (e,r,p) =>
      if e?
        return @send error:e
      if p.error
        return @send p
      @session.logged_in = p.userCtx.name
      @session.roles     = p.userCtx.roles
      return @send ok:true

  @get '/ccnq3/portal/logout.json': ->
    delete @session.logged_in
    return @send ok:true
