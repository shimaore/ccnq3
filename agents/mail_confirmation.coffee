#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'mail_confirmation.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
querystring = require 'querystring'

cdb = require process.cwd()+'/../lib/cdb.coffee'
portal_cdb = cdb.new (config.portal_couchdb_uri)

# Reference for mailer:  https://github.com/Marak/node_mailer

email = require 'mailer'


cdb_changes = require process.cwd()+'/../lib/cdb_changes.coffee'
cdb_changes.monitor config.portal_couchdb_uri, config.filter_name, undefined, (p) ->
  if p.error?
    return util.log(p.error)

  if not p.email? or not p.domain? or not p.confirmation_code?
    return util.log("Missing data: #{p.email} #{p.domain} #{p.confirmation_code}, skipping")

  email_options =
    to: p.email
    from: "support@#{p.domain}"
    subject: "Please confirm your registration with #{p.domain}"
    template: 'mail_confirmation.mustache'
    data:
      email: p.email
      domain: p.domain
      confirmation_code: p.confirmation_code
      link: "http://#{p.domain}/register/confirm/#{querystring.escape(p.email)}/#{querystring.escape(p.confirmation_code)}"

  email.send email_options, (err,result) ->
    # Do not attempt to update the status if the email was not sent
    if err?
      return util.log(err)

    # Email was sent, update the status in CouchBD
    p.status = 'confirmation_sent'
    portal_cdb.put p, (r) ->
      if r.error
        return util.log(r.error)
