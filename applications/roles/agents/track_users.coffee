#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'track_users.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
qs = require 'querystring'
child_process = require 'child_process'
uuid = require 'node-uuid'

cdb = require 'cdb'
users_cdb     = cdb.new config.users_couchdb_uri
databases_cdb = cdb.new config.databases_couchdb_uri

# Retrieve the UUID for a given (source,prefix) pair.
# Create a record in "databases" if none exist.
get_uuid = (source,prefix,cb)->
  # Check whether the database already exists
  json_key = JSON.stringify [ source, prefix ]
  databases_cdb.get json_key, (p)->
    if p.error isnt 'Missing'
      return util.log p.error

    if p.error is 'Missing'
      q =
        _id: json_key
        uuid: uuid()
        source: source
        prefix: prefix
      databases.put q, (r)->
        if r.error
          return util.log r.error
        cb r._id

    cb? p._id


cdb_changes = require 'cdb_changes'
options =
  uri: config.users_couchdb_uri
  filter_name: 'confirmed'
cdb_changes.monitor options, (user_doc) ->
  if user_doc.error?
    return util.log(user_doc.error)

  for source, prefixes of user_doc.access
    if config.sources[source]?
      get_uuid source, prefix
