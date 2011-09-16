
fs = require 'fs'
util = require 'util'

# Use a package-provided configuration file, if any.
config_location = process.env.npm_package_config_config_file

if not config_location?
  util.log "NPM did not provide a config_file parameter, process.env = #{ util.inspect process.env }"
  config_location = '/etc/ccnq3/host.json'

util.log "Using #{config_location} as configuration file."

exports.location = config_location

exports.config = JSON.parse fs.readFileSync config_location, 'utf8'

# TODO After reading the initial configuration and retrieving config.provisioning.couchdb_uri,
#      retrieve our CouchDB configuration record from the live database
#      and automatically save it
#      return the file configuration if the CouchDB query failed

exports.update = (content) ->
  fs.writeFileSync config_location, JSON.stringify content
