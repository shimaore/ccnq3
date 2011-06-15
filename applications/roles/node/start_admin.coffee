#!/usr/bin/env coffee

fs = require('fs')
config_location = process.env.npm_package_config_config_file or '/etc/ccnq3/roles.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8')).admin

zappa = require 'zappa'
zappa.run_file 'admin.coffee',
  port: [config?.port or 8767]
  hostname: config?.hostname or '127.0.0.1'
