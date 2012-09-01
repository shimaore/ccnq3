util = require 'util'
pico = require 'pico'

debug = false

# Use a package-provided configuration file, if any.
config_location = process.env.npm_package_config_file

make_id = (t,n) -> [t,n].join ':'

if not config_location?
  config_location = '/etc/ccnq3/host.json'
  util.log "NPM did not provide a config_file parameter, using #{config_location}." if debug

# Attempt to retrieve the last configuration from the database.
get = (cb)->
  util.log "Using #{config_location} as configuration file." if debug
  fs = require 'fs'
  try
    fs_config = JSON.parse fs.readFileSync config_location, 'utf8'
  catch error
    util.log "Reading #{config_location}: #{util.inspect error}"
    return cb {}
  rev = fs_config?._rev
  exports.retrieve fs_config, (config) ->
    # Save any new revision locally
    if rev isnt config._rev
      exports.update config
    # Callback
    cb config

module.exports = get

exports.get = ->
  console.warn "ccnq3_config.get(callback) is obsolete, use ccnq3_config(callback)."
  get arguments...

exports.location = config_location

exports.retrieve = (config,cb) ->
  if not config.host? or not config.provisioning? or not config.provisioning.host_couchdb_uri?
    util.log "Information to retrieve remote configuration is not available."
    return cb config

  username = make_id 'host', config.host
  provisioning = pico config.provisioning.host_couchdb_uri

  provisioning.retrieve username, (e,r,p) ->
    if e
      util.log "Retrieving live configuration failed: #{util.inspect e}; using file-based configuration instead."
      cb config
    else
      util.log "Retrieved live configuration." if debug
      cb p

exports.update = (content) ->
  util.log "Updating local configuration file." if debug
  fs = require 'fs'
  fs.writeFileSync config_location, JSON.stringify content
