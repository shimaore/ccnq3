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

cdb = require process.cwd()+'/../lib/cdb.coffee'
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

    cb p._id



cdb_changes = require process.cwd()+'/../lib/cdb_changes.coffee'
cdb_changes.monitor config.users_couchdb_uri, config.filter_name, (user_doc) ->
  if user_doc.error?
    return util.log(user_doc.error)

  user_doc.roles = user_doc.roles.filter (v)-> not v.match /-reader$/

  next = ()->
    users_cdb.put user_doc, (r)->
      if r.error
        return util.log r.error

  for source, prefixes of user_doc.access
    # Verify the source is valid
    if config.sources[source]?
      for prefix in prefixes
        next = ()->
          get_uuid source, prefix, (the_uuid)->
            user_doc.roles.push "#{the_uuid}-reader"
            next()

