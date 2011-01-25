###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

# Additional modules for the zappa server

express = require 'express'

app().http_server.use express.favicon()
app().http_server.use express.methodOverride()
app().http_server.use express.logger()

# Configuration

fs = require('fs')
config_location = 'server.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

def config: config

cdb = require process.cwd()+'/../lib/cdb.coffee'

def users_cdb: cdb.new (config.users_couchdb_uri)
