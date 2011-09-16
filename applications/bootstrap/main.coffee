#!/usr/bin/env coffee

zappa = require 'zappa'
zappa.run ->

  # Configuration
  config = require('ccnq3_config').config
  # Session store
  store = config.session_store()

  use 'logger'
    , 'bodyParser'
    , 'cookieParser'
    , session: { secret: config.session.secret, store: store }
    , 'methodOverride'

  # Provide access to "/public"
  use 'static': __dirname + '/public'
    , 'staticCache'

  def config: config

  # Let Zappa serve it owns versions.
  enable 'serve jquery', 'serve sammy'

  # applications/portal
  portal_modules = ['login','profile','recover','register']
  include __dirname + "../node_modules/ccnq3_portal/zappa/#{name}.coffee" for name in portal_modules

  # applications/roles
  roles_modules = ['login','admin','replicate']
  include __dirname + "../node_modules/ccnq3_roles/zappa/#{name}.coffee" for name in roles_modules

  # Provide a default index.html (default portal)
  get '/': ->
    @title = 'Bootstrap portal'
    @stylesheet = '/public/css/smoothness/jquery-ui.css'
    render 'index', layout:no

  view index: ->
    doctype 5
    html ->
      head ->
        title @title
        link rel:'stylesheet', href:@stylesheet
        # Zappa standard set
        script src: '/socket.io/socket.io.js'
        script src: '/zappa/jquery.js'
        script src: '/zappa/sammy.js'
        script src: '/zappa/zappa.js'
        # CCNQ3 standard set
        script src: '/public/js/jquery-ui.js'
        script src: '/public/js/jquery.validate.js'
        # Start the show
        script src: '/index.js'

      body ->

        header ->
          h1 @title or "Bootstrap portal"

        div id:'content', ->
          noscript ->
            div class:'error', -> 'Please enable Javascript in your web browser.'

        footer ->
          p '(c) 2011 Stéphane Alnet'

  client '/index.js': ->

    get '#/': ->

      $('#content').load '/content.html', ->
        portal_scripts = ['login','recover','register']
        $.getScript("/u/#{name}.js") for name in portal_scripts

        $.getScript("/roles/login.js")

  get '/content.html': ->
    if request.session.logged_in?
      render 'content', layout:no
    else
      render 'public', layout:no

  view public: ->
    div id:'login_container'
    div id:'register_container'
    div id:'password_recovery_container'

  view content: ->
    div -> "You are currently signed in, congratulations!"

  # Proxy all CouchDB accesses.
  httpProxy = require 'http-proxy'
  def proxy: new httpProxy.HttpProxy()

  get /^\/(_session|_users|provisioning|billing|cdr|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})($|\/)/, ->
    console.log "Proxying"
    proxy.proxyRequest request, response, { host:config.proxy.host, port:config.proxy.port }
