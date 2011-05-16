#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'ccnq2_register.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
querystring = require 'querystring'
crypto = require 'crypto'

request = require 'request'

cdb_changes = require process.cwd()+'/../../../lib/cdb_changes.coffee'
cdb_changes.monitor config.users_couchdb_uri, config.filter_name, undefined, (p) ->
  if p.error?
    return util.log(p.error)

  # Log in
  p =
    method: 'POST'
    uri: config.ccnq2_login_uri
    body: querystring.stringify
      username: config.ccnq2_admin_username
      password: config.ccnq2_admin_password

  request p, (error,response,body) ->
    if error or response.statusCode < 200 or response.statusCode > 299 or not body?
      return util.log(error or response.statusCode)

    # Submit record using the admin-level profile update defined in UserAuthentication
    p =
      method: 'PUT'
      uri: config.ccnq2_register_uri + p.name
      body: querystring.stringify
        name: [profile.first_name,profile.last_name].join(' ')
        email: profile.email
  
    request p

