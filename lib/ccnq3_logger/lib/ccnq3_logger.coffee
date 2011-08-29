
util    = require 'util'
config  = require('ccnq3_config').config
cdb     = require 'cdb'

exports.log = (data) ->
  # Use centralized logging if configured.
  if config.logger?.couchdb_uri?
    log_db = cdb.new config.logger.couchdb_uri
    log_db.put data, (r)->
      if r.error? then util.log util.inspect r
  # Otherwise use local logging.
  else
    util.log util.inspect r
