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

  Individual voicemail accounts (for example phone-number@domain) are registered
  as CouchDB users, and given access to a userDB.
  (A priori that userDB might be the same as some existing web-based user's,
  allowing for web voicemail, etc.).
  [In other words a given "userDB" can be shared by multiple user accounts.]

  The password for these voicemail accounts is the voicemail PIN.

  (Retrieval of voicemail messages from a TV-box might be done similarly by
  authenticating the box and giving it access to a userDB.)

  For leaving (inbound) voicemails, "system" accounts (for example 
  voicemail@host or @domain) are used which can create and update
  "voicemail" type records in the target's user database.
  (They also need to be able to read user accounts so that they know
  what the URI for a given userDB is.)

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

  server.on 'CONNECT', (req,res) ->

    # The XML dialplan provides us with the username
    # and already answer()ed the call.
    user  = req.channel_data.variable_vm_user
    mode  = req.channel_data.variable_vm_mode

    switch mode
      when 'record'
        util.log "Record for #{vm_user}"
        messaging.record config, res, vm_user

      when 'inbox'
        util.log "Inbox for #{vm_user}"
        messaging.inbox config, res, vm_user

      when 'main'
        util.log "Main for #{vm_user}"
        messaging.main config, res, vm_user

      else
        # FIXME say something
        server.force_disconnect()

  server.listen config.voicemail?.port ? 7123  # FIXME default_voicemail_port
