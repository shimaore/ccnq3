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

# "config" is the (possibly empty) configuration for the new host.
#
# "users_uri" and "provisioning_uri" and the URI for the matching
# databases, with administrative access. Since the new host is most
# probably NOT the local host, since the local host should be a
# management system, the admin URIs for _users and provisioning
# ought not to be present in the "config" record, and therefor must be
# provided separately.

# (However there's little chance this code will be used by anything
# but the bootstrap server, since all other hosts additions should
# be done by an admin account using the "host" couchapp.)

exports.record = (config,hostname,users_uri,provisioning_uri,keep_provisioning,cb)->
  username = "host@#{hostname}"

  users = cdb.new users_uri
  provisioning = cdb.new provisioning_uri

  salt = sha1_hex "a"+Math.random()
  password = sha1_hex "a"+Math.random()

  p =
    _id: "org.couchdb.user:#{username}"
    type: "user"
    name: username
    roles: ["host"]
    salt: salt
    password_sha: sha1_hex password+salt

  users.put p, (r)->
    if r.error?
      util.log util.inspect r
      throw failed: "Creating user record for #{username}"

    # Add the host in the main CDB's provisioning table,
    # with two initialization runnables.

    config.type = "host"
    config.host = hostname
    config._id  = "host:#{hostname}"
    config.change_handlers = [

        # TODO Storing change_handlers this way does not work.
        # TODO Also, why not simply store them as attachments, that way we'll be able to have different types (javascript, coffeescript, shell script, etc.) based on Content-Type.

        # Automatically save the new configuration in the static configuration file.
        (result,old_config,new_config) ->
          require('ccnq3_config').update new_config

        # Install the agent daemon in @reboot crontab.
        shell_runnable '''
            if crontab -l | grep -q ccnq3_host; then
              echo "Already installed."
            else
              (crontab -l; echo "@reboot cd && npm run-script ccnq3_host start") | crontab -;
            fi
          '''

      ]

    if not keep_provisioning
      # Update the provisioning URI to use the host's new username and password.
      url = require 'url'
      q = url.parse config.provisioning.couchdb_uri
      delete q.href
      delete q.host
      q.auth = "#{username}:#{password}"

      config.provisioning =
        couchdb_uri: url.format q

    provisioning.put config, (r)->
      if r.error?
        util.log util.inspect r
        throw failed: "Creating provisioning record for #{username}"
      cb? config
