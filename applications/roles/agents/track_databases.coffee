#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'track_databases.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
querystring = require 'querystring'
child_process = require 'child_process'

cdb = require process.cwd()+'/../lib/cdb.coffee'
replication_cdb = cdb.new config.replication_couchdb_uri

cdb_changes = require process.cwd()+'/../lib/cdb_changes.coffee'
cdb_changes.monitor config.databases_couchdb_uri, config.filter_name, (doc) ->
  if doc.error?
    return util.log(doc.error)

  # Typically target_db_name will be a UUID
  target_db_name = doc.uuid
  target_db_uri  = config.base_cdb_uri + target_db_name
  target_db      = cdb.new target_db_uri

  target_db.exists (it_does_exist) ->
    # Nothing to do if the database already exists
    return if it_does_exist

    # Create the database
    target_db.create ->

      # Make sure users with the specified role can access it.
      security_req =
        uri:"_security"
        body:
          # no admin roles => need to be _admin
          readers:
            roles: [ "access:#{doc.source}:#{doc.prefix}" ]

      target_db.req security_req, (r) ->
        if r.error
          return util.log(r.error)

        # Push the user couchapp into the database
        # FIXME Replace spawn with a call to the couchapp module, duh
        couchapp = child_process.spawn '/usr/bin/env', [
          'couchapp',
          config[doc.source].couchapp,
          target_db_uri
        ]

        couchapp.on 'exit', (code) ->
          if code isnt 0
            return util.log("CouchApp process exited with code "+code)

          util.log("Installation of #{src_couchapp} completed.")

          # Start replication
          replication_req =
            source: config[doc.source].db_uri
            target: target_db_uri
            filter: 'app/user_replication'
            query_params:
              prefix: querystring.escape(doc.prefix)

          replication_cdb.put replication_req, (r) ->
            if r.error
              return util.log(r.error)

