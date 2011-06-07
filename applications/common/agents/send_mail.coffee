#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = 'send_mail.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'

cdb = require process.cwd()+'/../lib/cdb.coffee'
send_mail_cdb = cdb.new (config.send_mail_couchdb_uri)

# Reference for Nodemailer:  https://github.com/andris9/Nodemailer

mailer = require 'nodemailer'

mailer.SMTP     = config.mailer.SMTP
mailer.sendmail = config.mailer.sendmail

cdb_changes = require process.cwd()+'/../lib/cdb_changes.coffee'
cdb_changes.monitor config.send_mail_couchdb_uri, config.filter_name, (p) ->
  if p.error?
    return util.log(p.error)

  if not p.from? or not p.to? or not p.subject? or not p.body?
    return util.log("Missing data: #{p.from} #{p.to} #{p.subject} #{p.body}, skipping")

  mailer.send_mail p, (err,status) ->
    # Do not attempt to update the status if the email was not sent
    if err?
      return util.log(err)

    # Email was submitted, update the status in CouchBD
    p.status = status
    portal_cdb.put p, (r) ->
      if r.error
        return util.log(r.error)
