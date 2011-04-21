#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'mail_password.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'
querystring = require 'querystring'
crypto = require 'crypto'

cdb = require process.cwd()+'/../../../lib/cdb.coffee'
users_cdb = cdb.new (config.users_couchdb_uri)

mailer = require 'nodemailer'

mailer.SMTP     = config.mailer.SMTP
mailer.sendmail = config.mailer.sendmail

password_charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-".split('')

random_password = (l) ->
  return '' if l is 0
  return random_password(l-1)+password_charset[Math.floor(Math.random()*password_charset.length)]

sha1_hex = (t) ->
  return crypto.createHash('sha1').update(t).digest('hex')


cdb_changes = require process.cwd()+'/../../../lib/cdb_changes.coffee'
cdb_changes.monitor config.users_couchdb_uri, config.filter_name, undefined, (p) ->
  if p.error?
    return util.log(p.error)

  password = random_password(16)

  # Assume document's "name" is the email address.
  # (There's also p.profile.email but might be an array.)
  if not p.name? or not p.domain?
    return util.log("Missing data: #{p.name} #{p.domain}, skipping")

  email_options =
    sender: "#{config.sender_local_part}@#{p.domain}"
    to: p.name
    subject: "Your password for #{p.domain}"
    body: """
              Someone (probably you) requested a new password for #{p.domain}.

              Your new password is: #{password}

              Thank you, and welcome to our exciting new service!
          """
    html: """
              <p>Someone (probably you) requested a new password for #{p.domain}.</p>
              <p>Your new password is <tt>#{password}</tt>.
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
