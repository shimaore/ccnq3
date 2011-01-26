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
#   GET /opensips/domain/?k=domain&v=12.34.56.78&c=domain
get '/opensips/domain/': ->
  t = line ("string" for field in @c)
  for local_ip in @v
    for entry in config[@local_ip]
      t += line (entry[field] for field in @c)
  return t

