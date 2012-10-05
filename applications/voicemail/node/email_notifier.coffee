##
# (c) 2012 Stephane Alnet
#

pico = require 'pico'
mailer = require 'nodemailer'
Milk = require 'milk'
util = require 'util'
qs = require 'querystring'
path = require 'path'

exports.notifier = (config) ->

  mailer.SMTP     = config.mailer.SMTP
  mailer.sendmail = config.mailer.sendmail

  file_base = config.voicemail.file_base

  send_notification_to = (number,msg_id) ->
    number_domain = config.voicemail.number_domain ? 'local'

    provisioning_db = pico config.provisioning.local_couchdb_uri
    provisioning_db.get "number:#{number}@#{number_domain}", (e,r,b) ->
      if e? or not b.user_database? then return

      sender = b.voicemail_sender ? config.voicemail?.sender
      user_db = pico config.voicemail.userdb_base_uri + '/' + b.user_database

      user_db.get msg_id, (e,r,msg) ->
        if e? then return

        user_db.get 'voicemail_settings', (e,r,b) ->
          return unless b.email_notifications
          for email, params of b.email_notifications
            send_email_notification email, params.attach_message, b.language, msg

      send_email_notification = (email,attach,language,msg) ->
        if attach
          file_name = 'voicemail_notification'
        else
          file_name = 'voicemail_notification_with_attachment'
        language ?= 'en'

        #### Templates

        # Default templates
        template =
          subject: 'New message from {{caller_id}}'
          body: '''
                  You have a new message from {{caller_id}}
                '''
          html: '''
                  <p>You have a new message from {{caller_id}}
                '''

        # Local templates
        get_templates = (cb,contents = ['subject','body','html']) ->
          if contents.length is 0
            cb()
            return

          content = contents.shift()
          uri_name = file_name + '.' + language + '.' + content

          # Templates in the server configuration
          ccnq3.config.attachment config, uri_name, (data) ->
            if data?
              template[content] = data
              get_templates cb, contents
              return

            # Templates stored on the local filesystem
            if file_base?
              template[content] = fs.readFileSync path.join(file_base,uri_name) , 'utf8', (err,data) ->
                if not err
                  template[content] = data
              get_templates cb, contents
            return

        #### Send email out
        send_email = ->
          email_options =
            sender: sender ? email
            to: email
            subject: Milk.render template.subject, msg
            body: Milk.render template.body, msg
            html: Milk.render template.html, msg
            attachments: []

          if attach and msg._attachments
            # Alternatively, enumerate the part#{n}.#{extension} files? (FIXME?)
            for name, data of msg._attachments
              do (name,data) ->
                # data fields might be: content_type, revpos, digest, length, stub:boolean
                email_options.attachments.push {
                  fileName: name
                  streamSource: user_db.request.get qs.escape(msg_id) + '/' + qs.escape(name)
                  contentType: data.content_type
                }

          mailer.send_mail email_options, (err,status) ->
            if err? or not status
              return util.log util.inspect err

        #### Get templates then send email
        get_templates send_email

  return send_notification_to
