#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Local configuration file

config = require('ccnq3_config').config

util = require 'util'
querystring = require 'querystring'
crypto = require 'crypto'

cdb = require 'cdb'
users_cdb = cdb.new (config.users.couchdb_uri)

mailer = require 'nodemailer'

mailer.SMTP     = config.mailer.SMTP
mailer.sendmail = config.mailer.sendmail

random_password = require 'password'

sha1_hex = (t) ->
  return crypto.createHash('sha1').update(t).digest('hex')


cdb_changes = require 'cdb_changes'
options =
  uri: config.users.couchdb_uri
  filter_name: "portal/send_password"
cdb_changes.monitor options, (p) ->
  if p.error?
    return util.log(p.error)

  password = random_password(3)

  # Assume document's "name" is the email address.
  # (There's also p.profile.email but might be an array.)
  if not p.name? or not p.domain?
    return util.log("Missing data: #{p.name} #{p.domain}, skipping")

  util.log "Sending new password to #{p.name}"

  email_options =
    sender: "#{config.mail_password.sender_local_part}@#{p.domain}"
    to: p.name
    subject: "Your password for #{p.domain}"
    body: """
              Someone (probably you) requested a new password for #{p.domain}.

              Your username is: #{p.name}
              Your new password is: #{password}

              Thank you, and welcome to our exciting new service!
          """
    html: """
              <p>Someone (probably you) requested a new password for <em>#{p.domain}</em>.</p>
              <p>Your username is <tt>#{p.name}</tt>
              <p>Your new password is <tt>#{password}</tt>
              </p>
              Thank you, and welcome to our exciting new service!
              </p>
          """

  mailer.send_mail email_options, (err,status) ->
    # Do not attempt to update the status if the email was not sent
    if err? or not status
      return util.log(err)

    # Email was sent, update the status in CouchBD
    delete p.send_password

    salt = sha1_hex "a"+Math.random()
    p.salt = salt
    p.password_sha = sha1_hex password+salt
    users_cdb.put p, (r) ->
      if r.error
        return util.log(r.error)
