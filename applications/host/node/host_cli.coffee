#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Create a username for the new host's main process so that it can bootstrap its own installation.
os = require 'os'
host = require './host.coffee'

# Load Configuration
fs = require('fs')
config_location = process.env.npm_package_config_bootstrap_file
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

hostname = os.hostname()

host.record hostname, config.couchdb_uri, (username,password)->
    url = require 'url'
    p = url.parse "#{config.couchdb_uri}/provisioning"
    delete p.href
    delete p.host
    p.auth = "#{username}:#{password}"

    config_file_name = process.env.npm_package_config_config_file
    fs.writeFileSync config_file_name, """
      {
        "provisioning_couchdb_uri": "#{url.format(p)}"
      }
    """

