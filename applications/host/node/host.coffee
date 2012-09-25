#!/usr/bin/env coffee
###
A library to install a manager host in a ccnq3 system.
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Create a username for the new host's main process so that it can bootstrap its own installation.
util = require 'util'
crypto = require 'crypto'
url = require 'url'

make_id = (t,n) -> [t,n].join ':'

host_username = (n) -> "host@#{n}"

sha1_hex = (t) ->
  return crypto.createHash('sha1').update(t).digest('hex')

exports.create_user = (users_db,hostname,cb) ->
  username = host_username hostname

  password = sha1_hex "a"+Math.random()

  p =
    _id: "org.couchdb.user:#{username}"
    type: "user"
    name: username
    roles: ["host"]
    password: password

  users_db.put p, (e)->
    if e?
      util.log util.inspect e
      throw "Creating user record for #{username}"

    util.log "Created user record for #{username}"
    cb? password


exports.update_config = (password,config,cb) ->
  # Since we are on a manager host, provisioning.couchdb_uri should be available.
  provisioning_uri = config.provisioning.couchdb_uri
  provisioning = pico provisioning_uri

  # The following are already done by bin/bootstrap.sh
  #
  #   config.type = "host"
  #   config.host = hostname
  #   config._id  = make_id 'host', hostname
  #

  # Compare with rewrite_host_couchdb_uri in ../couchapps/usercode/host.coffee
  rewrite_host_couchdb_uri = (doc,field) ->

    q = url.parse provisioning_uri
    delete q.href
    delete q.host
    q.auth = "#{username}:#{password}"

    field.host_couchdb_uri = url.format q

  username = host_username config.host

  # Update the provisioning URI to use the host's new username and password.
  config.provisioning.host_couchdb_uri = provisioning_uri
  # FIXME: why does local_couchdb_uri (on the manager) need to have admin access?
  # Possible answer: because it needs to install local _design documents.
  config.provisioning.local_couchdb_uri = provisioning_uri

  # Identically to what happens in ../couchapps/usercode/host.coffee when the
  # password is modified/set.
  rewrite_host_couchdb_uri doc, doc.provisioning
  rewrite_host_couchdb_uri doc, doc.logging

  provisioning_db.put config, (e)->
    if e?
      util.log util.inspect e
      throw "Creating provisioning record for #{username}"

    util.log "Created provisioning record for #{username}"
    cb? config
