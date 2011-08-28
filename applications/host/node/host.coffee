#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Create a username for the new host's main process so that it can bootstrap its own installation.
cdb = require 'cdb'
util = require 'util'
crypto = require 'crypto'

sha1_hex = (t) ->
  return crypto.createHash('sha1').update(t).digest('hex')

# shell_runnable generates a "runnable" function from a shell script.
shell_runnable = (script) ->
  (result,old_config,new_config) ->
    exec = require('child_process').exec
    exec script, {timeout:20}, (error,stdout,stderr)->
      result.script =
        code: script
        error: error
        stdout: stdout
        stderr: stderr


exports.record = (hostname,users_uri,provisioning_uri,cb)->
  username = "host@#{hostname}"

  users = cdb.new users_uri
  provisioning = cdb.new provisioning_uri

  salt = sha1_hex "a"+Math.random()
  password = sha1_hex "a"+Math.random()

  p =
    _id: "ord.couchdb.user:#{username}"
    type: "user"
    name: username
    roles: ["provisioning_reader"]
    salt: salt
    password_sha: sha1_hex password+salt

  users.put p, (r)->
    if r.error? then return util.log r.error

    # Add the host in the main CDB's provisioning table,
    # with two initialization runnables.

    p =
      type: "host"
      host: hostname
      _id: "host:#{hostname}"
      change_handlers: [

        # First runnable confirms that the agent is running and accessible.
        (result,old_config,new_config) ->
          result.running = true

        # Second runnable installs the agent daemon in @reboot crontab.
        shell_runnable '''
            if crontab -l | grep -q ccnq3_host; then
              echo "Already installed."
            else
              (crontab -l; echo "@reboot cd && npm run-script ccnq3_host start") | crontab -;
            fi
          '''

        # Third one automatically saves the new configuration
        (result,old_config,new_config) ->
          require('ccnq3_config').update new_config

      ]

    provisioning.put p, (r)->
      if r.error? then return util.log r.error

      cb? username, password
