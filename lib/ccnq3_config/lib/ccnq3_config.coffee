util = require 'util'

# Use a package-provided configuration file, if any.
config_location = process.env.npm_package_config_config_file

if not config_location?
  util.log "NPM did not provide a config_file parameter, process.env = #{ util.inspect process.env }"
  config_location = '/etc/ccnq3/host.json'

exports.location = config_location

exports.retrieve = (config,cb) ->
  if not config.host? or not config.provisioning?
    util.log "Information to retrieve remote configuration is not available."
    return cb p

  username = "host:#{config.host}"
  cdb = require 'cdb'
  provisioning = cdb.new config.provisioning.couchdb_uri

  provisioning.get username, (p) ->
    if p.error
      util.log "Retrieving live configuration failed: #{p.error}; using file-based configuration instead."
      cb config
    else
      util.log "Retrieved live configuration."
      cb p

exports.update = (content) ->
  fs = require 'fs'
  fs.writeFileSync config_location, JSON.stringify content

# Attempt to retrieve the last configuration from the database.
# Note: the configuration is not saved automatically since the
#       current process might not have proper permissions to do so.
exports.get = (cb)->
  util.log "Using #{config_location} as configuration file."
  fs = require 'fs'
  fs_config = JSON.parse fs.readFileSync config_location, 'utf8'
  exports.retrieve fs_config, (config) ->
    # Memoize the result
    exports.get = (cb)-> cb config
    cb config
