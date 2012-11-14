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

    config =
      _id: ccnq3.make_id "host", HOSTNAME
      type: "host"
      host: HOSTNAME
      provisioning:
        host_couchdb_uri: process.argv[2]
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
    if not process.env.CDB_URI?
      console.log "ERROR: You must provide CDB_URI."
      return 1

    CDB_URI = process.env.CDB_URI

    config =
      _id: ccnq3.make_id "host", HOSTNAME
      type: "host"
      host: HOSTNAME
      admin:
        couchdb_uri: CDB_URI
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
