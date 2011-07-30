#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

fs = require('fs')
config_location = process.env.npm_package_config_config_file
config = JSON.parse(fs.readFileSync(config_location, 'utf8')).portal

zappa = require 'stephane-zappa'
zappa.run_file 'main.coffee',
  port: [config.port]
  hostname: config.hostname
