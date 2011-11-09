#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Local configuration file

require('ccnq3_config').get (config)->

  util = require 'util'
  fs = require 'fs'

  # Reference for Nodemailer:  https://github.com/andris9/Nodemailer

  mailer = require 'nodemailer'

  mailer.SMTP     = config.mailer.SMTP
  mailer.sendmail = config.mailer.sendmail

  cdb_changes = require 'cdb_changes'
  options =
    uri: config.sotel_portal.couchdb_uri
    filter_name: 'replicate/partner_signup'
  cdb_changes.monitor options, (p) ->
    if p.error?
      return util.log(p.error)

    recipients =
      external: p.primary_contact.contact.email
      internal: config.sotel_portal.recipients

    file_base = config.sotel_portal.file_base

    for mode, recipient of recipients
      template = {}
      do (mode,recipient) ->
        try
          for content in ['subject','body','html']
            template[content] = fs.readFileSync file_base + p.state + '-' + mode + '.' + content
        catch error
          return

        email_options =
          sender: config.sotel_portal.partner_signup_from
          to: p.primary_contact.contact.email
          subject: Milk.render template.subject, p
          body: Milk.render template.body, p
          html: Milk.render template.html, p

        mailer.send_mail p, (err,status) ->
          if err?
            return util.log(err)
