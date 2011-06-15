#!/usr/bin/env coffee

zappa = require 'zappa'
zappa.run_file 'prepaid.coffee',
  port: [parseInt(process.env.npm_package_config_port) or 8765]
  hostname: process.env.npm_package_config_hostname or '127.0.0.1'
