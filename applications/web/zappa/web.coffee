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

    # No site-specific login additions.
    @coffee '/login.js': ->

      $(document).ready ->
        extra_login = $.extra_login

        $.extra_login = (auth,next) ->

          # Replicate any sotel_portal record
          provisioning_replicate = (auth,next) ->
            auth.notify 'Replicating provisioning data.'
            options =
              type: 'post'
              url: '/roles/replicate/pull/provisioning'
              dataType:'json'
              success: (data) ->
                if not data.ok
                  auth.notify 'Provisioning replication failed.'
                  return
                auth.notify ''
                next()
            auth.$.ajax(options)

          if extra_login?
            extra_login auth, -> provisioning_replicate auth, next
          else
            provisioning_replicate auth, next

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
          jar: false
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
