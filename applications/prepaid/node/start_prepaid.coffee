#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

require('ccnq3_config').get (config)->

  zappa = require 'zappa'
  zappa.run_file 'prepaid.coffee',
    port: [config.prepaid.port] # 8756
    hostname: config.prepaid.hostname # '127.0.0.1'
