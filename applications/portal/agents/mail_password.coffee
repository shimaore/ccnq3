#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

# Local configuration file

require('ccnq3_config').get (config)->

  util = require 'util'
  querystring = require 'querystring'
  crypto = require 'crypto'

  # For templates
  fs = require 'fs'
  Milk = require 'milk'

  cdb = require 'cdb'
  users_cdb = cdb.new (config.users.couchdb_uri)

  mailer = require 'nodemailer'

  mailer.SMTP     = config.mailer.SMTP
  mailer.sendmail = config.mailer.sendmail

  random_password = require 'password'

  file_base = config.portal.file_base
  file_name = 'portal_password'

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

    util.log "Assigning new password to #{p.name}"

    # Push the new password into the database.
    delete p.send_password

    p.password = password

    users_cdb.put p, (r) ->
      if r.error
        return util.log("cdb PUT failed: #{r.error}")

      # Notify via email.
      util.log "Notifying #{p.name} of new password for #{p.domain}"

      template =
        subject: 'Your password for {{domain}}'
        body: '''
                  Someone (probably you) requested a new password for {{domain}}.

                  Your username is: {{name}}
                  Your new password is: {{password}}

                  Thank you, and welcome to our exciting new service!
              '''
        html: '''
                  <p>Someone (probably you) requested a new password for <em>{{domain}}</em>.</p>
                  <p>Your username is <tt>{{name}}</tt>
                  <p>Your new password is <tt>{{password}}</tt>
                  </p>
                  Thank you, and welcome to our exciting new service!
                  </p>
              '''

      if file_base?
        for content in ['subject','body','html']
          try
            template[content] = fs.readFileSync file_base + file_name + '.' + content, 'utf8'

      # Extend the document with the new password so that the templates
      # may use it.
      p.password = password

      email_options =
        sender: "#{config.mail_password.sender_local_part}@#{p.domain}"
        to: p.name
        subject: Milk.render template.subject, p
        body: Milk.render template.body, p
        html: Milk.render template.html, p

      mailer.send_mail email_options, (err,status) ->
        if err? or not status
          return util.log("Email failed: #{err}")
