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

cdb = require process.cwd()+'/../../../lib/cdb.coffee'
users_cdb = cdb.new (config.users_couchdb_uri)

mailer = require 'nodemailer'

mailer.SMTP     = config.mailer.SMTP
mailer.sendmail = config.mailer.sendmail


cdb_changes = require process.cwd()+'/../../../lib/cdb_changes.coffee'
cdb_changes.monitor config.users_couchdb_uri, config.filter_name, undefined, (p) ->
  if p.error?
    return util.log(p.error)

  # Assume document's "name" is the email address.
  # (There's also p.profile.email but might be an array.)
  if not p.name? or not p.domain? or not p.confirmation_code?
    return util.log("Missing data: #{p.name} #{p.domain} #{p.confirmation_code}, skipping")

  email_options =
    sender: "#{config.sender_local_part}@#{p.domain}"
    to: p.name
    subject: "Please confirm your registration with #{p.domain}"
    body: """
              Someone (probably you) registered with our service at #{p.domain}.
              To confirm your email address, please go to:
              <https://#{p.domain}/u/register/confirm.html>
              then copy and paste the following confirmation code:
                #{p.confirmation_code}

              Thank you, and welcome to our exciting new service!
          """
    html: """
              <p>Someone (probably you) registered with our service at #{p.domain}.
              To confirm your email address, please click on the following link:
              <a href="https://#{p.domain}/u/register/confirm/email=#{querystring.escape(p.email)}&code=#{querystring.escape(p.confirmation_code)}">Confirm my email address</a>.
              <p>
              </p>
              Thank you, and welcome to our exciting new service!
              </p>
          """

  mailer.send_mail email_options, (err,status) ->
    # Do not attempt to update the status if the email was not sent
    if err? or not status
      return util.log(err)

    # Email was sent, update the status in CouchBD
    p.status = "confirmation_sent"
    users_cdb.put p, (r) ->
      if r.error
        return util.log(r.error)
