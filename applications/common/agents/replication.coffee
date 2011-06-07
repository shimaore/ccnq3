#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = process.ARGV[2] or 'replication.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
querystring = require 'querystring'

cdb = require 'cdb'

# The replication database should contains documents suitable
# for POSTing to /_replicate, i.e.:
#   doc =
#     source:
#     target:
#     filter:
#     query_params:
#
# When a replication document is deleted, the corresponding
# replication is stopped.

target_db = cdb.new config.base_couchdb_uri
replicate = (doc,cb) ->
  req =
    method: 'POST'
    uri:    '_replicate'
    body:
      source: doc.source
      target: doc.target
      continuous: true
  if doc.deleted
    req.body.cancel = true
  if doc.filter?
    req.body.filter = doc.fitler
    req.body.query_params = doc.query_params

  target_db.req doc, (r) ->
    if r.error
      return util.log(r.error)
    cb?(r)

# The replication database is always called "replication".
replication_couchdb_uri = config.base_couchdb_uri+'/replication'
replication_cdb = cdb.new replication_couchdb_uri

# At startup create a replication instance for each object in the replication_cdb
replication_cdb.req { uri: '/_all_docs' }, (replication_doc) ->
  if replication_doc.error?
    return util.log(replication_doc.error)
  replicate(replication_doc)

# Then monitor changes to update replications as needed.
cdb_changes = require 'cdb_changes'
cdb_changes.monitor replication_couchdb_uri, config.filter_name, (replication_doc) ->
  if replication_doc.error?
    return util.log(replication_doc.error)
  replicate(replication_doc)

