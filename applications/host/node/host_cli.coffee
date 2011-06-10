#!/usr/bin/env coffee

# Create a username for the new host's main process so that it can bootstrap its own installation.
os = require 'os'
host = require './host.coffee'

hostname = os.hostname()

host.record hostname, process.env.CDB_URI, (username,password)->
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

