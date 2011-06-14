#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Local configuration file

fs = require 'fs'
config_location = process.ARGV[2] or 'send_mail.config'
config = JSON.parse(fs.readFileSync(config_location, 'utf8'))

util = require 'util'

cdb = require 'cdb'
send_mail_cdb = cdb.new (config.send_mail_couchdb_uri)

# Reference for Nodemailer:  https://github.com/andris9/Nodemailer

mailer = require 'nodemailer'

mailer.SMTP     = config.mailer.SMTP
mailer.sendmail = config.mailer.sendmail

cdb_changes = require 'cdb_changes'
options =
  uri: config.send_mail_couchdb_uri
  filter_name: config.filter_name
cdb_changes.monitor options, (p) ->
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
