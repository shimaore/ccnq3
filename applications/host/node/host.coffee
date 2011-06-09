#!/usr/bin/env coffee

# Create a username for the new host's main process so that it can bootstrap its own installation.
os = require 'os'

cdb = require 'cdb'
util = require 'util'

sha1_hex = (t) ->
  return crypto.createHash('sha1').update(t).digest('hex')

# shell_runnable generates a "runnable" function from a shell script.
shell_runnable = (script) ->
  # Ignore the "host" parameter as we do not use it.
  (result) ->
    exec = require('child_process').exec
    exec script, {timeout:20}, (error,stdout,stderr)->
      result.script =
        code: script
        error: error
        stdout: stdout
        stderr: stderr


hostname = os.hostname()
username = "host@#{hostname}"

users = cdb.new "#{process.env.CDB_URI}/_users"
provisioning = cdb.new "#{process.env.CDB_URI}/provisioning"

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
  if r.error? return util.log r.error

  # Add the host in the main CDB's provisioning table,
  # with two initialization runnables.

  p =
    type: "host"
    host: hostname
    _id: "host:#{hostname}"
    runnables: [
      # First runnable confirms that the agent is running and accessible.
      (result,host) -> host.bootstrapped = true
      # Second runnable installs the agent daemon in @reboot crontab.
      shell_runnable '''
          if crontab -l | grep -q host/agents; then
            echo "Already installed."
          else
            (crontab -l; echo "@reboot $HOME/ccnq3/applications/host/agents/host start") | crontab -;
          fi
        '''
    ]

  provisioning.put p, (r)->
    if r.error? return util.log r.error

    url = require 'url'
    p = url.parse "#{process.env.CDB_URI}/provisioning"
    delete p.href
    delete p.host
    p.auth = "#{username}:#{password}"

    fs.writeFileSync process.ARGV[2], """
      {
        "provisioning_couchdb_uri": "#{url.format(p)}"
      }
    """

