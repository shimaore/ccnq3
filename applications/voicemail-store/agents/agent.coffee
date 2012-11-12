#!/usr/bin/env coffee

pico = require 'pico'
handler = require './voicemail'

require('ccnq3').config (config) ->

  src = pico config.provisioning.host_couchdb_uri
  options =
    since_name: "voicemail-store"
    filter_name: "voicemail-store/numbers"

  src.monitor options, handler
