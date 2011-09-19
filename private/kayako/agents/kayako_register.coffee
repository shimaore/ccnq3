#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Local configuration file

require('ccnq3_config').get (config)->

  util = require 'util'
  qs = require 'querystring'
  crypto = require 'crypto'

  request = require 'request'

  kayako_request = (method,controller,args,cb) ->

    salt = "1029381092"

    sha256 = crypto.createHmac 'sha256',config.kayako_register.secret_key
    sha256.update salt.toString()
    signature = sha256.digest 'base64'

    params = qs.stringify(args)+'&'+qs.stringify
      e: controller
      signature: signature
      apikey: config.kayako_register.api_key
      salt: salt

    q =
      method: method
      uri: config.kaykao_register.api_url+if method is 'GET' then params else ""
      headers:
        "Content-Type": "application/x-www-form-urlencoded"
      body: if method isnt 'GET' then params else ""

    util.log util.inspect {q:q}

    request q, cb



  cdb_changes = require 'cdb_changes'
  options:
    uri: config.users.couchdb_uri
    filter_name: "portal/confirmed"
  cdb_changes.monitor options, (p) ->
    if p.error?
      return util.log(p.error)

    q =
      fullname: [p.profile.first_name,p.profile.last_name].join(' ')
      usergroupid: 2
      password: "poiuytrfghbnji897t6yghjki987ty"
      email: p.profile.email

    kayako_request 'POST', '/Base/User', q

