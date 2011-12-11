#!/usr/bin/env coffee
# A simple web server for the entire portal.
# Provides static files, redirections.

url = require 'url'
request = require 'request'

require('zappa').run 8080, ->
  @use 'logger', static: __dirname

  @enable 'default layout'

  @get '/', ->
    @render 'default',
      stylesheets: [
        '/public/css/smoothness/jquery-ui'
        '/public/css/datatables'
        '/public/menu/menu'
      ]
      scripts: [
        '/public/js/default'
        '/u/content'
        '/public/menu/menu'
      ]

  @view 'default': ->
    div id:'content', ->
      noscript 'Please enable JavaScript'
      div id:'login_container'
      div id:'password_recovery_container'
      div id:'register_container'


  make_proxy = (proxy_base) ->
    return ->
      console.log "Proxying"
      proxy = request
        uri: proxy_base + @request.url
        headers: @request.headers
        timeout: 10000
      console.log "Sending request"
      @request.pipe proxy
      console.log "Receiving response"
      proxy.pipe @response
      console.log "OK"

  methods = [@get,@put,@post,@del]

  portal_proxy = make_proxy 'http://127.0.0.1:8765'
  portal_urls = /^\/(u|roles)\/.*$/
  for m in methods
    m portal_urls, portal_proxy

  couchdb_proxy = make_proxy 'http://127.0.0.1:5984'
  couchdb_urls = /^\/(_session|_users|provisioning|billing|cdr|u[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})($|\/)/
  for m in methods
    m couchdb_urls, couchdb_proxy
