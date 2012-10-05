util = require 'util'
pico = require 'pico'
qs = require 'querystring'

debug = false

#### CCNQ3 Tools
#

#### ccnq3.make_id(type,name)
#
# Returns a proper CouchDB _id for a type and name.
#
make_id = (t,n) -> [t,n].join ':'

exports.make_id = make_id

#### Configuration management
#
# ccnq3.config manages configuration files for CCNQ3

# Use a package-provided configuration file, if any.
config_location = process.env.npm_package_config_file

if not config_location?
  config_location = '/etc/ccnq3/host.json'
  util.log "NPM did not provide a config_file parameter, using #{config_location}." if debug

#### ccnq3.config(callback)
#
# Attempt to retrieve the last configuration from the database or the local copy.
# The callback receives the configuration, or an empty hash if none can be retrieved.
get = (cb)->
  util.log "Using #{config_location} as configuration file." if debug
  fs = require 'fs'
  try
    fs_config = JSON.parse fs.readFileSync config_location, 'utf8'
  catch error
    util.log "Reading #{config_location}: #{util.inspect error}"
    return cb {}
  rev = fs_config?._rev
  retrieve fs_config, (config) ->
    # Save any new revision locally
    if rev isnt config._rev
      update config
    # Callback
    cb config

module.exports.config = get
module.exports.config.location = config_location

#### ccnq3.config.retrieve(config,callback)
# Attempt to retrieve the configuration from the provisioning database.
# The original config parameter is passed to the callback if the remote retrieval failed.
retrieve = (config,cb) ->
  if not config.host? or not config.provisioning? or not config.provisioning.host_couchdb_uri?
    util.log "Information to retrieve remote configuration is not available."
    return cb config

  username = make_id 'host', config.host
  provisioning = pico config.provisioning.host_couchdb_uri

  provisioning.get username, (e,r,p) ->
    if e
      util.log "Retrieving live configuration failed: #{util.inspect e}; using file-based configuration instead."
      cb config
    else
      util.log "Retrieved live configuration." if debug
      cb p

module.exports.config.retrieve = retrieve

#### ccnq3.config.attachment(config,name,callback(data))
# Attempt to retrieve the attachment from the provisioning database.
# The callback will receive null if the attachment could not be retrieved.
attachment = (config,name,cb) ->
  if not config.host? or not config.provisioning? or not config.provisioning.host_couchdb_uri?
    util.log "Information to retrieve attachment is not available."
    return cb null

  username = make_id 'host', config.host
  provisioning = pico config.provisioning.host_couchdb_uri
  uri = ([username,name].map qs.escape).join '/'

  provisioning.request.get uri, (e,r,p) ->
    if e
      util.log "Retrieving attachment #{uri} failed: #{util.inspect e}." if debug
      cb null
    else
      cb p

module.exports.config.attachment = attachment

#### ccnq3.config.update(config)
# Attempt to save the given configuration in the local storage.
update = (content) ->
  if not content?
    util.log "Cannot update empty configuration."
    return
  util.log "Updating local configuration file." if debug
  fs = require 'fs'
  fs.writeFileSync config_location, JSON.stringify content

module.exports.config.update = update

#### ccnq3.db
#
module.exports.db =
  # Update ACLs and code
  #### ccnq3.db.security(db_uri,name,trust_hosts)
  # Updates the security record for the given database, using the given name as the database type.
  # Additionally, remote hosts are allowed to read/write the database if the `trust_hosts` flag is true.
  security: (uri,name,trust_hosts) ->
    db = pico uri

    db.request.get '_security', json:true, (e,r,p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("#{name}_admin") if p.admins.roles.indexOf("#{name}_admin") < 0

      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("#{name}_writer") if p.readers.roles.indexOf("#{name}_writer") < 0
      p.readers.roles.push("#{name}_reader") if p.readers.roles.indexOf("#{name}_reader") < 0
      if trust_hosts
        # Hosts have direct access to the database
        p.readers.roles.push("host") if p.readers.roles.indexOf("host") < 0

      db.request.put '_security', json:p
