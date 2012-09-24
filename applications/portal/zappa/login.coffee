###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

#### portal/login.coffee
#
# This modules allows authentication for operations under the
# `/ccnq3/portal` and `/ccnq3/roles` APIs as provided by the
# default portal.

@include = ->

  pico = require 'pico'
  url = require 'url'
  querystring = require 'querystring'

  config = null
  require('ccnq3_config') (c) ->
    config = c

  couchdb_auth = (username,password,cb) ->
    uri = url.parse config.session.couchdb_uri
    uri.auth = "#{querystring.escape username}:#{querystring.escape password}"
    delete uri.href
    delete uri.host
    session_db = pico url.format uri
    session_db.request.get jar:false, json:true, (e,r,p) ->
      if e?
        return cb e
      if p.error
        return cb p.error
      cb null, p.userCtx

  # Browser-based login.
  @post '/ccnq3/portal/login.json': ->
    username = @request.param 'username'
    if not username?
      return @send error:'Missing username'
    password = @request.param 'password'
    if not password?
      return @send error:'Missing password'

    couchdb_auth username, password, (e,u) =>
      if e?
        @send error:e
      else
        @session.logged_in = u.name
        @session.roles     = u.roles
        @send ok:true

  error = (code,msg) ->
    err = new Error msg
    err.status = code
    return err

  # Soft-authorization: if an Authorization header is given, use it to create
  # a session if none exist already.
  @use (req,res,next) ->
    # Do not overwrite existing session.
    if req.session.logged_in
      return next()
    # Source: https://github.com/senchalabs/connect/blob/master/lib/middleware/basicAuth.js
    authorization = req.headers.authorization
    # No Authorization provided: rely on existing session.
    if not authorization
      return next()
    parts = authorization.split ' '
    if parts.length isnt 2
      return next error 400, 'Invalid Authorization header'
    scheme = parts[0]
    if scheme isnt 'Basic'
      return next error 400, 'Unsupported scheme in Authorization header'
    credentials = new Buffer(parts[1],'base64').toString().split(':')
    [user,pass] = credentials
    couchdb_auth user, pass, (e,p) ->
      if e
        next e
      else
        req.session.logged_in = u.name
        req.session.roles     = u.roles
        next()

  # Browser-based logout.
  @get '/ccnq3/portal/logout.json': ->
    delete @session.logged_in
    return @send ok:true
