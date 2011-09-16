#!/usr/bin/env coffee
###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

config = require('ccnq3_config').config

zappa = require 'zappa'
zappa.run config.sotel_portal.port, config.sotel_portal.hostname, ->

  # Configuration
  ccnq3_config = require 'ccnq3_config'
  config = ccnq3_config.config
  # Session store
  store = ccnq3_config.session_store()

  use 'logger'
  , 'bodyParser'
  , 'cookieParser'
  , session: { secret: config.session.secret, store: store }
  , 'methodOverride'

  def config: config

  def cdb: require 'cdb'

  # Let Zappa serve it owns versions.
  enable 'serve jquery', 'serve sammy'

  # applications/portal
  portal_modules = ['login','profile','recover','register']
  include __dirname + "/../node_modules/ccnq3_portal/zappa/#{name}.coffee" for name in portal_modules

  # applications/roles
  roles_modules = ['login','admin','replicate']
  include __dirname + "/../node_modules/ccnq3_roles/zappa/#{name}.coffee" for name in roles_modules

  # This gets everything started.
  coffee '/p/main.js': ->
    $(document).ready ->
      default_scripts = [
          '/public/js/jquery-ui',
          '/public/js/jquery.validate',
          '/public/js/jquery.jsonforms',
          # '/public/js/sammy',
          # '/public/js/jquery.deserialize',
          '/public/js/jquery.smartWizard-2.0',
          '/p/content'
      ]
      for s in default_scripts
        $.getScript s + '.js'

  include 'content.coffee'
  include 'login.coffee'

  include 'actions/default.coffee'
  include 'actions/sip_signup.coffee'
  include 'actions/partner_signup.coffee'
