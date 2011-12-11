#!/usr/bin/env coffee
# A simple web server for the entire portal.
# Provides static files, redirections.

url = require 'url'
request = require 'request'

require('zappa').run 8080, ->
  @use static: __dirname

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
      the_url = proxy_base + @request.url
      method = @request.method.toLowerCase()
      proxy = request[method] the_url
      @request.pipe proxy
      proxy.pipe @response

  methods = [@get,@put,@post,@del]

  portal_proxy = make_proxy 'http://127.0.0.1:8765'
  portal_urls = /^\/(u|roles)\/.*$/
  for m in methods
    m portal_urls, portal_proxy

  couchdb_proxy = make_proxy 'http://127.0.0.1:5984'
  couchdb_urls = /^\/(_session|_users|provisioning|billing|cdr|u[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})($|\/)/
  for m in methods
    m couchdb_urls, couchdb_proxy
