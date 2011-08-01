#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

config = require('ccnq3_config').config

zappa = require 'stephane-zappa'
zappa.run_file 'main.coffee',
  port: [config.opensips_proxy.port]
  hostname: config.opensips_proxy.hostname
