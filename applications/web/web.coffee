#!/usr/bin/env coffee
# A simple web server for the entire portal.
# Provides static files, redirections.

url = require 'url'
request = require 'request'
fs = require 'fs'

require('ccnq3_config').get (config) ->
  require('zappa').run 8080, ->
    @use 'logger'

    @enable 'default layout'

    @get '/', ->
      @render 'default',
        stylesheets: [
          '/public/css/smoothness/jquery-ui'
          '/public/css/datatables'
          '/public/menu/menu'
          '/public/css/style'
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

    types =
      js: 'application/javascript'
      css: 'text/css'
      png: 'image/png'
      jpeg: 'image/jpeg'
      gif: 'image/gif'

    @get /^\/public\//, ->
      type = @request.url.match(/\.([a-z]+)$/)?[1]
      if type of types
        @response.contentType types[type]
        @send fs.readFileSync __dirname + @request.url
      else
        @send 'Unknown document type'

    make_proxy = (proxy_base) ->
      return ->
        proxy = request
          uri: proxy_base + @request.url
          method: @request.method
          headers: @request.headers
          timeout: 1000
        @request.pipe proxy
        proxy.pipe @response
        return

    portal_proxy = make_proxy "http://#{config.portal.hostname}:#{config.portal.port}"
    portal_urls = /^\/(u|roles)\/.*$/
    @get  portal_urls, portal_proxy
    @post portal_urls, portal_proxy
    @put  portal_urls, portal_proxy
    @del  portal_urls, portal_proxy

    couchdb_proxy = make_proxy 'http://127.0.0.1:5984'
    couchdb_urls = /^\/(_session|_users|provisioning|billing|cdr|u[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})($|\/)/
    @get  couchdb_urls, couchdb_proxy
    @post couchdb_urls, couchdb_proxy
    @put  couchdb_urls, couchdb_proxy
    @del  couchdb_urls, couchdb_proxy
