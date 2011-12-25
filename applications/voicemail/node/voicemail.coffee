#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

###
  This is the ccnq3 ESL voicemail server.

  This script accepts an incoming call,
  creates a FIFO for bi-directional audio,
  and proceeds with handling the call.

  FIFO relays are created as needed to record or play
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
cdb = require 'cdb'

require('ccnq3_config').get (config)->

  # esl.debug = true

  Unique_ID = 'Unique-ID'

  server = esl.createServer (res) ->

    res.connect (req,res) ->

      # Retrieve channel parameters
      channel_data = req.body

      unique_id             = channel_data[Unique_ID]
      util.log "Incoming call UUID = #{unique_id}"

      vm_box     = channel_data.variable_sip_req_uri # or sip_to_uri

      # Common values

      on_disconnect = (req,res) ->
        util.log "Receiving disconnection"
        switch req.headers['Content-Disposition']
          when 'linger'      then res.exit()
          when 'disconnect'  then res.end()

      res.on 'esl_disconnect_notice', on_disconnect

      force_disconnect = (res) ->
        util.log 'Hangup call'
        res.bgapi "uuid_kill #{unique_id}"

      # Code handling

          res.on 'esl_event', (req,res) ->
            switch req.body['Event-Name']

              when 'CHANNEL_HANGUP_COMPLETE'
                util.log 'Channel hangup complete'

              else
                util.log "Unhandled event #{req.body['Event-Name']}"

          on_connect = (req,res) ->

              # Check whether the call can proceed
              check_time () ->

                util.log 'Bridging call'
                res.execute 'answer', (req,res) ->
                  util.log "Call answered"

          # Handle the incoming connection
          res.linger (req,res) ->
            res.filter Unique_ID, unique_id, (req,res) ->
              res.event_json 'ALL', on_connect

  server.listen(config.voicemail.port)
