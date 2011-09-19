#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

require('ccnq3_config').get (config)->

  zappa = require 'stephane-zappa'
  zappa.run_file 'main.coffee',
    port: [config.opensips_proxy.port]
    hostname: config.opensips_proxy.hostname
