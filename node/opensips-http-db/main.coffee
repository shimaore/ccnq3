#!/usr/bin/env zappa

app 'opensips', (server) ->
  server.use (require 'express').bodyDecoder()

# Get configuration
fs = require('fs')
config_location = 'server.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def config: config

def line: (a) ->
  a.join("\t") + "\n"

# Typical:
#   GET /opensips/domain/?k=domain&v=requested_domain&c=domain

get '/opensips/domain/': ->
  t = line ["string"]
  t += line [@v] if config.domains[@v]?
  return t

