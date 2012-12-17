#!/usr/bin/env coffee
# (c) 2011 Stephane Alnet
# License: APGL3+

NAME='ccnq3'
SRC="/opt/#{NAME}/src"

###
Usage:
  CDB_URI=uri bootstrap.coffee  Creates manager host: uses existing CouchDB database
  bootstrap.coffee URI          Creates non-manager host
###

fs = require 'fs'
npm = require 'npm'
ccnq3 = require 'ccnq3'
url = require 'url'

make_amqp_uri = (uri) ->
  u = url.parse uri
  delete u.href
  u.protocol = 'amqp'
  delete u.host
  delete u.port
  delete u.pathname
  delete u.search
  delete u.path
  delete u.query
  delete u.hash
  url.format u

run = ->

  if not fs.existsSync SRC
    console.log "ERROR: You must install the #{NAME} package before calling this script."
    return 1

  process.chdir SRC

  CONF = ccnq3.config.location

  if fs.existsSync CONF
    console.log "Skipping configuration: #{CONF} already exists."
    return 1

  HOSTNAME=require("os").hostname()
  INTERFACES=require('./interfaces')()

  if process.argv[2]?

    # Non-manager installation
    cdb_uri = process.argv[2]

    if not cdb_uri?
      console.log "ERROR: You must provide CDB_URI."
      return 1

    amqp_uri = make_amqp_uri cdb_uri

    config =
      _id: ccnq3.make_id "host", HOSTNAME
      type: "host"
      host: HOSTNAME
      amqp_uri: amqp_uri
      provisioning:
        host_couchdb_uri: cdb_uri
      applications: [
        "applications/monitor"
        "applications/host"
      ]
      source: SRC
      account: ""
      updated_at: 0
      interfaces: INTERFACES

  else

    # Manager installation
    cdb_uri = process.env.CDB_URI

    if not cdb_uri?
      console.log "ERROR: You must provide CDB_URI."
      return 1

    amqp_uri = make_amqp_uri cdb_uri

    config =
      _id: ccnq3.make_id "host", HOSTNAME
      type: "host"
      host: HOSTNAME
      admin:
        couchdb_uri: cdb_uri
        amqp_uri: amqp_uri
        system: true
      applications: [
        # "applications/usercode"
        "applications/provisioning"
        # "applications/roles"
        "applications/logging"
        "applications/monitor"
        "applications/host"
        # "applications/portal"
        # "applications/inbox"
        # "public"
        # "applications/web"
        "applications/cdrs"
        "applications/locations"
        "applications/couch_daemon"
        "applications/voicemail-store"
      ]
      source: SRC
      account: ""
      updated_at: 0
      interfaces: INTERFACES
    # applications/usercode: creates the usercode database: must be first since all others depend on it
    # applications/provisioning: creates the provisioning database: must be second
    # applications/roles: updates the _users databases: must be third
    # applications/logging: host pre-requires logging
    # applications/portal: portal pre-requires host

  ccnq3.config.update config

  console.log "Update"
  npm.load {}, (er) ->
    if er
      process.exit 1
    npm.commands['run-script'] ['updates'], (er) ->
      if er
        process.exit 1

      # Do not restart just yet.
      console.log "Bootstrap local host"
      npm.commands['run-script'] ['bootstrap'], (er) ->
        if er
          process.exit 1

        console.log "Restart"
        npm.commands.start (er) ->
          if er
            process.exit 1

          console.log """
            Installation done.
          """
  return

sync_exit = run()
if sync_exit?
  process.exit sync_exit
