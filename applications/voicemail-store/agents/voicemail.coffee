pico = require 'pico'
couchapp = require 'couchapp'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

config = null
require('ccnq3').config (c) -> config = c

failure = (o) -> console.dir o

module.exports = (doc) ->

  user_database = doc.user_database

  id = "number:#{doc.number}"

  if not user_database.match /^u[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/
    return failure error:"Invalid db name #{user_database}"

  target_db_uri = config.users.userdb_base_uri + '/' + user_database
  target_db = pico target_db_uri

  users_db = pico config.users.couchdb_uri
  users_db.view 'replicate', 'userdb', qs: {key:JSON.stringify user_database}, (e,r,b) =>
    if e? then return failure error:e, when:"view users for #{user_database}"

    readers_names = (row.value for row in b.rows)

    # Create the database
    target_db.create =>

      # We do not check the return code:
      # it's OK if the database already exists.

      # Restrict number of available past revisions.
      target_db.request.put '_revs_limit',body:"10", (e,r,b) =>
        if e? then return failure error:e, when:"set revs_limit for #{user_database}"

      # Make sure the users can access it.
      target_db.request.get '_security', json:true, (e,r,b) =>
        if e? then return failure error:e, when:"retrieve security object for #{user_database}"

        b.readers ?= {}

        b.readers.names = readers_names
        b.readers.roles = [ 'update:user_db:' ] # e.g. voicemail

        target_db.request.put '_security', json:b, (e,r,b) =>
          if e? then return failure error:e, when:"update security object for #{user_database}"

      # Install the design documents
      try
        push_script target_db_uri, 'usercode'
      catch e
        return failure error:e, when:"replicate design documents into #{user_database}"
