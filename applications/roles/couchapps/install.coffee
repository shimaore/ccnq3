#!/usr/bin/env coffee

couchapp = require 'couchapp'
cdb = require 'cdb'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

# Load Configuration
cfg = require 'ccnq3_config'
cfg.get (config) ->

  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'

  update = (uri) ->
    # Set the security object for the _users source database.
    users = cdb.new uri
    users.security (p)->
      p.admins ||= {}
      p.admins.roles ||= []
      p.admins.roles.push("users_admin")   if p.admins.roles.indexOf("users_admin") < 0
      p.readers ||= {}
      p.readers.roles ||= []
      p.readers.roles.push("users_writer") if p.readers.roles.indexOf("users_writer") < 0
      p.readers.roles.push("users_reader") if p.readers.roles.indexOf("users_reader") < 0

    push_script uri, 'main'

  users_uri = config.users?.couchdb_uri
  if users_uri
    update users_uri
    return

  # There's no need to create the database, however we must reference it.
  users_uri = config.install?.users?.couchdb_uri ? config.admin.couchdb_uri + '/_users'

  update users_uri

  # FIXME: public_uri is most probably not the proper base URI
  # (it should be replaced with a https://example.com/ URI).
  # This should be requested the first time the admin logs in
  # after the installation.
  url = require 'url'
  q = url.parse config.admin.couchdb_uri
  delete q.href
  delete q.host
  delete q.auth
  public_uri = url.format(q).replace(/\/$/,'')

  replicate_uri   = config.install?.users?.replicate_uri   ? config.admin.couchdb_uri + '/_replicate'
  userdb_base_uri = config.install?.users?.userdb_base_uri ? config.admin.couchdb_uri

  config.users ?=
    couchdb_uri: users_uri
    replicate_uri: replicate_uri
    userdb_base_uri: userdb_base_uri
    public_userdb_base_uri: public_uri # FIXME
  cfg.update config
