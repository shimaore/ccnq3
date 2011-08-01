#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

config = require('ccnq3_config').config

zappa = require 'zappa'
zappa.run_file 'prepaid.coffee',
  port: [config?.prepaid?.port or 8756]
  hostname: config?.prepaid?.hostname or '127.0.0.1'
