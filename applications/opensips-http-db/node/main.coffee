#!/usr/bin/env zappa
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

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
  if config.domains[@v]?
    return line(["string"]) + line([@v])
  else
    return ""

