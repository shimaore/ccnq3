util = require 'util'

# Use a package-provided configuration file, if any.
config_location = process.env.npm_package_config_config_file

make_id = (t,n) -> [t,n].join ':'

if not config_location?
  config_location = '/etc/ccnq3/host.json'
  util.log "NPM did not provide a config_file parameter, using #{config_location}."

exports.location = config_location

exports.retrieve = (config,cb) ->
  if not config.host? or not config.provisioning? or not config.provisioning.host_couchdb_uri?
    util.log "Information to retrieve remote configuration is not available."
    return cb config

  username = make_id 'host', config.host
  pico = require 'pico'
  provisioning = pico config.provisioning.host_couchdb_uri

  provisioning.retrieve username, (e,r,p) ->
    if e
      util.log "Retrieving live configuration failed: #{e}; using file-based configuration instead."
      cb config
    else
      util.log "Retrieved live configuration."
      cb p

exports.update = (content) ->
  util.log "Updating local configuration file."
  fs = require 'fs'
  fs.writeFileSync config_location, JSON.stringify content

# Attempt to retrieve the last configuration from the database.
# Note: the configuration is not saved automatically since the
#       current process might not have proper permissions to do so.
exports.get = (cb)->
  util.log "Using #{config_location} as configuration file."
  fs = require 'fs'
  try
    fs_config = JSON.parse fs.readFileSync config_location, 'utf8'
  catch error
    util.log "Reading #{config_location}: #{error}"
    return cb {}
  rev = fs_config?._rev
  exports.retrieve fs_config, (config) ->
    # Memoize the result
    exports.get = (cb)-> cb config
    # Save any new revision locally
    if rev isnt config._rev
      exports.update config
    # Callback
    cb config
