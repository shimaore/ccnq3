#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

pico = require 'pico'
util = require 'util'

make_id = (t,n) -> [t,n].join ':'
host_username = (n) -> "host@#{n}"
sha1_hex = (t) ->
  return require('crypto').createHash('sha1').update(t).digest('hex')

# Load Configuration
ccnq3 = require 'ccnq3'
ccnq3.config (config) ->

  hostname = config.host

  if config.admin?.system
    # Manager host
    users_db = pico config.users.couchdb_uri

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
        util.error util.inspect e

      config.password = password
      ccnq3.config.update config
      # The configuration will be saved in the database by applications/provisioning.

  else

    # Non-manager host

    local_provisioning_uri = config.provisioning.local_couchdb_uri
    local_provisioning = pico local_provisioning_uri
    local_provisioning.create ->
      local_provisioning.request.put '_revs_limit',body:"10", (e,r,b) =>
        if e? then console.dir failure error:e, when:"set revs_limit for #{local_provisioning_uri}"
