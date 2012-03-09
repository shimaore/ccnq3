#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

###
  This is the ccnq3 ESL voicemail server.

  mod_httapi is used to record or play
  files to/from remote CouchDB. (This avoids having to download
  audio prompts, or store then upload recorded messages.)

  Voicemail content is stored as .wav PCM mono 16 bits (generated
  by FreeSwitch) which can then be transcoded.
  (RIFF (little-endian) data, WAVE audio, Microsoft PCM, 16 bit, mono 8000 Hz)

  The authentication is done using our standard CouchDB access.

  Individual voicemail accounts (number@number_domain) are gathered from
  the provisioning database, and given access to a userDB.
  (A priori that userDB should be the same as some existing web-based user's,
  allowing for web voicemail, etc.).

  The password for these voicemail accounts is the voicemail PIN
  stored in the "voicemail_settings" record in that user's database.

  (Retrieval of voicemail messages from a TV-box will be done by
  authenticating the box and giving it access to a userDB.)

  For leaving (inbound) voicemails, "system" accounts (in the form
  voicemail@host) are used which can create and update
  "voicemail" type records in the target's user database.

  The receiving user record (a priori the voicemail account's) must contain:

    notification.email  (mailto URI)
    notification.wmi    (SIP URI)

  Attachments:

    name.wav      WAV 16 bits (8kHz or higher)
    prompt.wav    WAV 16 bits (8kHz or higher)

###

esl = require 'esl'
util = require 'util'
querystring = require 'querystring'

messaging = require './messaging'

require('ccnq3_config').get (config)->

  # esl.debug = true

  server = esl.createCallServer()

  messaging.notifier = require('./notifier').notifier config
  messaging.email_notifier = require('./email_notifier').notifier config

  server.on 'CONNECT', (call) ->

    # The XML dialplan provides us with the username
    # and already answer()ed the call.
    user  = call.body.variable_vm_user
    mode  = call.body.variable_vm_mode

    switch mode
      when 'record'
        util.log "Record for #{user}"
        call.linger ->
          messaging.record config, call, user

      when 'inbox'
        util.log "Inbox for #{user}"
        messaging.inbox config, call, user

      when 'main'
        util.log "Main for #{user}"
        messaging.main config, call, user

      else
        # FIXME say something
        call.command 'hangup'

  server.listen config.voicemail?.port ? 7123  # FIXME default_voicemail_port
