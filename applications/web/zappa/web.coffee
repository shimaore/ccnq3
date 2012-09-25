#!/usr/bin/env coffee
# A simple web server for the entire portal.
# Provides static files, redirections.

url = require 'url'
request = require 'request'
fs = require 'fs'
util = require 'util'

require('ccnq3').config (config) ->
  options = config.web?.options ? {}
  options.port ?= 8080
  require('zappajs').run options, ->
    @use 'logger'

    @enable 'default layout'

    @get '/', ->
      @render 'default',
        stylesheets: [
          '/public/css/default'
          '/public/css/web'
        ]
        scripts: [
          '/public/js/default'
          '/ccnq3/portal/content'
        ]

    # No site-specific login additions.
    @coffee '/login.js': ->

      $(document).ready ->
        extra_login = $.ccnq3.portal.extra_login

        # Replicate any provisioning record
        extra_login.push (auth,next) ->
          auth.notify 'Replicating provisioning data.'
          ee = $.ccnq3.roles.replicate.pull 'provisioning'
          ee.on 'success', ->
            auth.notify ''
            next()
          ee.on 'error', ->
            auth.notify 'Provisioning replication failed.'
            return

    @view 'default': ->
      div id:'menu_container'
      div id:'content', ->
        noscript 'Please enable JavaScript'
        div id:'login_container'
        div id:'password_recovery_container'
        div id:'register_container'
      div id:'log'

    types =
      js: 'application/javascript'
      css: 'text/css'
      png: 'image/png'
      jpeg: 'image/jpeg'
      gif: 'image/gif'

    public_cache = (url) ->
      public_cache[url] ?= fs.readFileSync __dirname + url

    @get /^\/public\//, ->
      type = @request.url.match(/\.([a-z]+)$/)?[1]
      if type of types
        @response.contentType types[type]
        @send public_cache @request.url
      else
        @send 'Unknown document type'

    make_proxy = (proxy_base) ->
      return ->
        proxy = request
          uri: proxy_base + @request.url
          method: @request.method
          headers: @request.headers
          jar: false
          timeout: 30000
        , (e,r,b) =>
          if e?
            util.log @request.url + ' failed with error ' + util.inspect e
        @request.pipe proxy
        proxy.pipe @response
        return

    portal_proxy = make_proxy "http://#{config.portal.hostname}:#{config.portal.port}"
    portal_urls = /^\/ccnq3\//
    @get  portal_urls, portal_proxy
    @post portal_urls, portal_proxy
    @put  portal_urls, portal_proxy
    @del  portal_urls, portal_proxy

    couchdb_proxy = make_proxy 'http://127.0.0.1:5984'
    couchdb_urls = /^\/(_session|_users|_uuids|_utils|_all_dbs|_active_tasks|_config|provisioning|billing|cdr|cdrs|locations|u[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})($|\/)/
    @get  couchdb_urls, couchdb_proxy
    @post couchdb_urls, couchdb_proxy
    @put  couchdb_urls, couchdb_proxy
    @del  couchdb_urls, couchdb_proxy
