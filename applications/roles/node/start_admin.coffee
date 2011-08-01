#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

config = require('ccnq3_config').config

zappa = require 'zappa'
zappa.run_file 'admin.coffee',
  port: [config.prepaid.admin_port] # 8767
  hostname: config.prepaid.admin_hostname # '127.0.0.1'
