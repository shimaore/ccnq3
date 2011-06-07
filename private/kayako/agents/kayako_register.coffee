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
qs = require 'querystring'
crypto = require 'crypto'

request = require 'request'

kayako_request = (method,controller,args,cb) ->

  salt = "1029381092"

  sha256 = crypto.createHmac 'sha256',config.secret_key
  sha256.update salt.toString()
  signature = sha256.digest 'base64'

  params = qs.stringify(args)+'&'+qs.stringify
    e: controller
    signature: signature
    apikey: config.api_key
    salt: salt

  q =
    method: method
    uri: config.api_url+if method is 'GET' then params else ""
    headers:
      "Content-Type": "application/x-www-form-urlencoded"
    body: if method isnt 'GET' then params else ""

  util.log util.inspect {q:q}

  request q, cb



cdb_changes = require process.cwd()+'/../../../lib/cdb_changes.coffee'
cdb_changes.monitor config.users_couchdb_uri, config.filter_name, (p) ->
  if p.error?
    return util.log(p.error)

  q =
    fullname: [p.profile.first_name,p.profile.last_name].join(' ')
    usergroupid: 2
    password: "poiuytrfghbnji897t6yghjki987ty"
    email: p.profile.email

  kayako_request 'POST', '/Base/User', q

