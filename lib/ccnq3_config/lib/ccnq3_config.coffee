
fs = require 'fs'
util = require 'util'
cdb = require 'cdb'

# Use a package-provided configuration file, if any.
config_location = process.env.npm_package_config_config_file

if not config_location?
  util.log "NPM did not provide a config_file parameter, process.env = #{ util.inspect process.env }"
  config_location = '/etc/ccnq3/host.json'

util.log "Using #{config_location} as configuration file."

exports.location = config_location

exports.config = JSON.parse fs.readFileSync config_location, 'utf8'

exports.retrieve = (config,cb) ->
  username = "host@#{config.hostname}"
  provisioning = cdb.new config.provisioning.couchdb_uri

  provisioning.get username, (p) ->
    if p.error
      return util.log "Retrieving live configuration failed: #{p.error}"
    exports.config = p
    cb?(p)

exports.update = (content) ->
  fs.writeFileSync config_location, JSON.stringify content

# Attempt to retrieve the last configuration from the database.
# Note: the configuration is not saved automatically since the
#       current process might not have proper permissions to do so.
exports.retrieve exports.config
