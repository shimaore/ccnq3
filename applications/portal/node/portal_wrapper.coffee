#!/usr/bin/env coffee

zappa = require 'zappa'
zappa.run_file 'portal.coffee',
  port: 8765
  hostname: '127.0.0.1'
