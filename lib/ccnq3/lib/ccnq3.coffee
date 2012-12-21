util = require 'util'
pico = require 'pico'
qs = require 'querystring'

debug = false

#### ccnq3.amqp

# The default exchange for this application is called `ccnq3`.
# For example:
#
#     require('ccnq3').amqp (connection) ->
#       exchange = connection.exchange()
#       exchange.publish 'log', {error:"boo"}
#
defaultExchangeName = 'ccnq3'

# config.amqp might be a amqp[s] URI or any of the structures amqp.createConnection might accept.
amqp = (cb) ->
  # Memoize / avoid duplicates
  if module.exports.amqp.connection?
    cb module.exports.amqp.connection
  else
    # Try to build a new connection based on the configuration.
    get (config) ->
      if config.amqp?
        if typeof config.amqp is 'string'
          connection = require('amqp').createConnection {url: config.amqp}, {defaultExchangeName}
        else
          connection = require('amqp').createConnection config.amqp, {defaultExchangeName}
        module.exports.amqp.connection = connection
        connection.on 'ready', ->
          cb? connection
      else
        cb? null
  return

module.exports.amqp = amqp

#### ccnq3.log(msg)
# Logs a message or object to AMQP (if available) or to stderr.
log = (msg) ->
  amqp (connection) ->
    if connection?
      options =
        type: 'fanout'
        durable: true
      connection.exchange defaultExchangeName, options, (exchange) ->
        if typeof msg is 'string'
          exchange.publish 'log', {msg}
        else
          exchange.publish 'log', msg
    else
      if typeof msg is 'string'
        util.error msg
      else
        util.error util.inspect msg
  return

module.exports.log = log

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
  util.error "NPM did not provide a config_file parameter, using #{config_location}." if debug

#### ccnq3.config(callback)
#
# Attempt to retrieve the last configuration from the database or the local copy.
# The callback receives the configuration, or an empty hash if none can be retrieved.
get = (cb)->
  util.error "Using #{config_location} as configuration file." if debug
  fs = require 'fs'
  try
    fs_config = JSON.parse fs.readFileSync config_location, 'utf8'
  catch error
    util.error "Reading #{config_location}: #{util.inspect error}"
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
    util.error "Information to retrieve remote configuration is not available."
    return cb config

  username = make_id 'host', config.host
  provisioning = pico config.provisioning.host_couchdb_uri

  provisioning.get username, (e,r,p) ->
    if e
      util.error "Retrieving live configuration failed: #{util.inspect e}; using file-based configuration instead."
      cb config
    else
      util.error "Retrieved live configuration." if debug
      cb p

module.exports.config.retrieve = retrieve

#### ccnq3.config.attachment(config,name,callback(data))
# Attempt to retrieve the attachment from the provisioning database.
# The callback will receive null if the attachment could not be retrieved.
attachment = (config,name,cb) ->
  if not config.host? or not config.provisioning? or not config.provisioning.host_couchdb_uri?
    util.error "Information to retrieve attachment is not available."
    return cb null

  username = make_id 'host', config.host
  provisioning = pico config.provisioning.host_couchdb_uri
  uri = ([username,name].map qs.escape).join '/'

  provisioning.request.get uri, (e,r,p) ->
    if e? or r.statusCode isnt 200
      util.error "Retrieving attachment #{uri} failed: #{util.inspect e}." if debug
      cb null
    else
      cb p

module.exports.config.attachment = attachment

#### ccnq3.config.update(config)
# Attempt to save the given configuration in the local storage.
update = (content) ->
  if not content?
    util.error "Cannot update empty configuration."
    return
  util.error "Updating local configuration file." if debug
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
