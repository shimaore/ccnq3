#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'track_roles.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
querystring = require 'querystring'
child_process = require 'child_process'

cdb = require process.cwd()+'/../lib/cdb.coffee'
portal_cdb = cdb.new (config.portal_couchdb_uri)
replication_cdb = cdb.new config.replication_couchdb_uri

# Reference for mailer:  https://github.com/Marak/node_mailer

email = require 'mailer'


cdb_changes = require process.cwd()+'/../lib/cdb_changes.coffee'
cdb_changes.monitor config.portal_couchdb_uri, config.filter_name, undefined, (user_doc) ->
  if user_doc.error?
    return util.log(user_doc.error)

  for role in user_doc.roles
    if role.match(/^account:/)
      prefix = role.substr('account:'.length)
      for src_couchapp, src_db_uri of config.source_databases
        target_db_uri = src_db_uri + querystring.escape('$' + prefix)
        target_db = cdb.new target_db_uri
        target_db.exists (it_does_exist) ->
          # Nothing to do if the database already exists
          return if it_does_exist

          # Create the database
          target_db.create ->

            # Make sure users with the specified role can access it.
            security_req =
              uri:"_security"
              body:
                readers:
                  roles: [role]

            target_db.req security_req, (r) ->
              if r.error
                return util.log(r.error)

              # Push the user couchapp into the database
              couchapp = child_process.spawn '/usr/bin/env', [
                'couchapp',
                process.cwd()+'../couchapp/'+src_couchapp,
                target_db_uri
              ]

              couchapp.on 'exit', (code) ->
                if code isnt 0
                  return util.log("CouchApp process exited with code "+code)
                return util.log("Installation of #{src_couchapp} completed.")

              # Start replication
              replication_req =
                source: src_db_uri
                target: target_db_uri
                filter: 'app/user_replication'
                query_params:
                  prefix: querystring.escape(prefix)

              replication_cdb.put replication_req, (r) ->
                if r.error
                  return util.log(r.error)

