#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet
#
# Monitors the local system and pushes data into CouchDB
# at set intervals.

pico = require 'pico'

default_plugins = [
  'os'
  'process'
  'processes'
  'interrupts'
  'diskstats'
  'meminfo'
  'netdev'
  'stat'
  'vmstat'
]

minutes = 60*1000 # ms

get_data = (plugins,cb) ->

  get_data_of = (n,data,cb) ->
    if n >= plugins.length
      return cb data

    plugin = plugins[n]
    p = require "./plugins/#{plugin}"

    p.get (error,rec) ->
      if error?
        data.errors ?= {}
        data.errors[p.name] = error
      data[plugin] = rec if rec?

      get_data_of n+1, data, cb

  get_data_of 0, {}, cb

require('ccnq3').config (config) ->

  plugins = config.monitor?.plugins ? default_plugins
  db = config.monitor?.host_couchdb_uri
  interval = config.monitor?.interval ? 5*minutes

  if db?
    db = pico db
    hostname = require('os').hostname()

    run = ->
      now = new Date()
      get_data plugins, (data) ->
        data.hostname = hostname
        data.timestamp = now
        data._id = [ hostname, now.toJSON() ] .join ' '
        db.put data, (e) ->
          if e?
            console.dir e

    setInterval run, interval
    run()

  else
    console.log "Missing configuration, not starting the monitor service."
