#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Local configuration file

require('ccnq3_config').get (config)->

  util = require 'util'
  qs = require 'querystring'

  request = require 'request'

  cdb_changes = require 'cdb_changes'
  options =
    uri: config.users.couchdb_uri
    filter_name: 'portal/confirmed'
  cdb_changes.monitor options, (p) ->
    if p.error?
      return util.log(p.error)

    # Log in
    q =
      method: 'POST'
      uri: config.ccnq2.login_uri+'?'+qs.stringify
        username: config.ccnq2.admin_username
        password: config.ccnq2.admin_password

    request q, (error,response,body) ->
      if error or response.statusCode < 200 or response.statusCode > 399 or not body?
        return util.log(error or response.statusCode)

      cookie = response.headers['set-cookie'].toString().split(/;/)[0]

      # Submit record using the admin-level profile update defined in UserAuthentication
      q =
        method: 'PUT'
        uri: config.ccnq2.register_uri + p.name
        headers:
          cookie: cookie
        body: qs.stringify
          name: [p.profile.first_name,p.profile.last_name].join(' ')
          email: p.profile.email
    
      request q
