#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

config = require('ccnq3_config').config

zappa = require 'stephane-zappa'
zappa.run_file 'portal.coffee',
  port: [config.portal.port]
  hostname: config.portal.hostname
