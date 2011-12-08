#!/usr/bin/env coffee

couchapp = require 'couchapp'

push_script = (uri, script,cb) ->
  couchapp.createApp require("./#{script}"), uri, (app)-> app.push(cb)

cfg = require 'ccnq3_config'
cfg.get (config)->

  users_uri = config.users.couchdb_uri
  push_script users_uri, 'main'

  usercode_uri = config.usercode.couchdb_uri
  push_script usercode_uri, 'usercode'

  # Initialize parameters required for the portal.

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

  config.portal ?=
    port: config.install?.portal?.port ? 8765
    hostname: config.install?.portal?.hostname ? '127.0.0.1' # ? config.host
    # file_base: ..
  config.session ?=
    secret: config.install?.session?.secret ? 'a'+Math.random()
    couchdb_uri: config.install?.session?.couchdb_uri ? public_uri + '/_session'
  config.mail_password ?=
    sender_local_part: config.install?.mail_password?.sender_local_part ? 'support'
  config.mailer ?=
    sendmail: config.install?.mailer?.sendmail ? '/usr/sbin/sendmail'

  cfg.update config
