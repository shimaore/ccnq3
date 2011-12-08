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
