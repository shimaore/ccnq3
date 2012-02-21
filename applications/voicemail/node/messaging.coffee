# messaging.coffee
# (c) 2012 Stephane Alnet
# License: AGPL3+

util = require 'util'
pico = require 'pico'
request = require 'request'

fs = require 'fs'
child_process = require 'child_process'

hangup = (req,res) -> res.hangup()

timestamp = -> new Date().toJSON()

###
  play_and_get_digits has the following arguments:
    min_digits
    max_digits
    max_tries
    timeout
    valid_terminators
    prompt_audio_file
    bad_input_audio_file
    var_name
    digits_regex
    digit_timeout
    transfer_on_failure
###

goodbye = (res) ->
  res.execute 'phrase', 'voicemail_goodbye', hangup

##
# Message "part" (segments/fragments) are numbered out from 1.
the_first_part = 1

message_min_duration = 5
message_max_duration = 300

class Message

  ##
  # new Message db_uri, _id
  # new Message db_uri, timestamp, caller_id, uuid
  constructor: (@db_uri,timestamp,caller_id,uuid) ->
    if not uuid?
      @id = timestamp
    else
      @timestamp = timestamp
      @caller_id = caller_id
      @uuid = uuid
      @id = 'voicemail:' + timestamp + uuid
    @db = pico @db_uri
    @msg_uri = @db.prefix @id
    @part = the_first_part

  # Record the current part
  start_recording: (req,res,cb) ->
    cb ?= (req,res) => @post_recording req,res
    @db.rev @id, (e,r,b) =>
      if not b?.rev?
        util.log "start_recording: Missing document #{@id}"
        return
      fifo_path = "/tmp/#{@id}.PCMU"
      upload_url = "#{@msg_uri}/part#{@part}.wav?rev=#{b.rev}"
      child_process.exec "/usr/bin/mkfifo -m 0660 '#{fifo_path}'", (error) =>
        if error?
          util.log "start_recording: Could not mkfifo"

        # Start the proxy on the fifo
        fs.createReadStream(fifo_path).pipe request.put upload_url
        # Note: I ended up not using mod_httapi because the name parser
        # didn't know what to do of "extension .wav?rev=1-....".

        # Play beep to indicate we are ready to record
        res.execute 'set', 'RECORD_WRITE_ONLY=true', (req,res) =>
          res.execute 'set', 'playback_terminators=#1234567890', (req,res) =>
            res.execute 'gentones', '%(500,0,800)', (req,res) =>

              # FIXME save "req.body.variable_record_seconds" somewhere

              res.execute 'record', "#{fifo_path} #{message_max_duration} 20 3", (req,res) ->
                # The DTMF that was pressed is available in req.body.playback_terminator_used

                # Note: record has no "minimum duration".
                # We manually junk the segment if it is too short.
                if req.body.record_seconds < message_min_duration
                  # FIXME this will probably break if the fifo-proxy hasn't had time to finish pushing the
                  # content (and therefor the attachment has not been fully inserted).
                  # Additionally this might have the wrong "rev" if the document was inserted.
                  request.del upload_url

                # Remove the FIFO
                fs.unlink fifo_path, ->
                  cb req,res

  # Delete parts
  delete_parts: (cb) ->
    @db.retrieve @id, (e,r,b) ->
      # Remove all attachments
      b._attachments = {}
      @db.update b, cb

  # Post-recording menu
  post_recording: (req,res) ->
    # Check whether the attachment exists (it might be deleted if it doesn't match the minimum duration)
    request.head "#{@msg_uri}/part#{@part}.wav", (e) ->
      if e?
        res.execute 'phrase', "could not record please try again", (req,res) ->
          @start_recording req, res
        return

      res.execute 'play_and_get_digits', "1 1 1 15000 # phrase:'to-start-over to-listen to-append to-finish:1234' phrase:'invalid choice' choice \\d 3000", (req,res) ->
        switch req.body.variable_choice
          when "1"
            @delete_parts ->
              @part = the_first_part
              @start_recording req, res
          when "2"
            @listen_recording req, res, the_first_part
          when "3"
            @part++
            @start_recording req, res
          else
            goodbye res

  # Play the parts one after the other; when the last part is played, call the optional callback
  listen_recording: (req,res,this_part,cb) ->
    cb ?= (req,res) -> @post_recording req,res
    request.head "#{@msg_uri}/part#{this_part}.wav", (error) ->
      if error
        # Presumably we've read all the parts
        return cb req, res
      else
        res.execute 'playback', "#{@msg_uri}/part#{this_part}.wav", (req,res) ->
          listen_recording req, res, this_part+1, cb

  # Play the message enveloppe
  play_enveloppe: (req,res,cb) ->
    @db.retrieve @id, (e,r,b) =>
      if not b?
        util.log "play_enveloppe: Missing #{@id}"
        return
      res.execute 'play_and_get_digits', "1 1 1 1000 # phrase:'message received:#{b.timestamp}:#{b.caller_id}' silence_stream://250 choice \\d 1000", (req,res) ->
        if req.body.variable_choice
          cb req, res, req.body.variable_choice
        else
          cb req, res

  # Play a recording, calling the callback with an optional collected digit
  play_recording: (req,res,this_part,cb) ->
    request.head "#{@msg_uri}/part#{this_part}.wav", (error) ->
      if error
        cb req, res
      else
        res.execute 'play_and_get_digits', "1 1 1 1000 # #{msg_uri}/part#{this_part}.wav silence_stream://250 choice \\d 1000", (req,res) ->
          if req.body.variable_choice
            # Act on user interaction
            cb req, res, req.body.variable_choice
          else
            # Keep playing
            play_recording req, res, this_part+1, cb

  # Create a new voicemail record in the database
  create: (req,res,cb) ->
    msg =
      type: "voicemail"
      _id: @id
      timestamp: @timestamp ? timestamp()
      box: 'new' # In which box is this message?
      caller_id: @caller_id

    # Create new CDB record to hold the voicemail metadata
    @db.update msg, (e) ->
      if e
        util.log "Could not create #{msg_uri}"
        res.execute 'phrase', "sorry", hangup
        return
      cb req,res


class User

  constructor: (@db_uri,@user) ->
    @user_db = pico @db_uri

  voicemail_settings: (req,res,cb) ->
    # Memoize
    if @vm_settings?
      return cb @vm_settings

    @user_db.retrieve 'voicemail_settings', (e,r,vm_settings) =>
      if e
        util.log "VM Box for #{@user} is not available from #{@db_uri}."
        res.execute 'phrase', 'vm_say:sorry', hangup
        return
      else
        @vm_settings = vm_settings # Memoize
        cb vm_settings

  play_prompt: (req,res,cb) ->
    @voicemail_settings req, res, (vm_settings) ->
      if vm_settings._attachments?["prompt.wav"]
        res.execute 'playback', @db_uri + '/voicemail_settings/prompt.wav', cb

      else if vm_settings._attachments?["name.wav"]
        res.execute 'phrase', "voicemail_record_message,#{@db_uri}/voicemail_settings/name.wav", cb

      else
        res.execute 'phrase', "voicemail_record_message,#{@user}", cb

  authenticate: (req,res,cb,attempts) ->
    attempts ?= 3
    if attempts <= 0
      return goodbye res

    @voicemail_settings req, res, (vm_settings) ->
      wrap_cb = ->
        if vm_settings.language?
          res.execute 'set',  "language=#{vm_settings.language}", (req,res) ->
            res.execute 'phrase', 'voicemail_hello', cb
        else
          res.execute 'phrase', 'voicemail_hello', cb

      if vm_settings.pin?
        res.execute 'play_and_get_digits', "4 10 1 15000 # phrase:'voicemail_enter_pass:#' phrase:'voicemail_fail_auth' pin \\d+ 3000", (req,res) ->
          if req.body.variable_pin is vm_settings.pin
            do wrap_cb
          else
            @authenticate req, res,cb, attempts-1
      else
        do wrap_cb

  new_messages: (req, res,cb) ->
    @user_db.view 'voicemail', 'new_messages', (e,r,b) ->
      if e
        return cb req, res
      res.execute 'phrase', "voicemail_message_count,#{b.total_rows}:new", (req,res) -> cb req, res, b.rows

  saved_messages: (req, res,cb) ->
    @user_db.view 'voicemail', 'saved_messages', (e,r,b) ->
      if e
        return cb req, res
      res.execute 'phrase', "voicemail_message_count,#{b.total_rows}:saved", (req,res) -> cb req, res, b.rows

  navigate_messages: (req,res,rows,current,cb) ->
    # Exit once we reach the end or there are no messages, etc.
    if current < 0 or not rows? or current >= rows.length
      return cb req, res

    navigate = (req,res,key) ->
      switch key
        when "1"
          if current is 0
            res.execute 'phrase', 'no previous message', (req,res)->
              @navigate_messages req, res, rows, current, cb
            return
          @navigate_messages req, res, rows, current-1, cb

        when "2"
          if current is rows.length-1
            res.execute 'phrase', 'no next message', (req,res)->
              @navigate_messages req, res, rows, current, cb
          @navigate_messages req, res, rows, current+1, cb

    msg = new Message @db_uri, rows[current]._id
    msg.play_enveloppe req,res, (req,res,choice) =>
      if choice?
        navigate req, res, choice
      else
        # Default navigation is: read next message
        @navigate_messages req, res, rows, current+1, cb

  config_menu: (req,res,cb) ->
    res.execute 'play_and_get_digits', '1 1 1 15000 # phrase:voicemail_config_menu:1:2:3:4:5 silence_stream://250 choice \\d', (req,res) ->
      switch req.body.variable_choice
        when "1"
          record_greetings req,res,cb
        when "2"
          choose_greetings req,res,cb
        when "3"
          choose_name res,res,cb
        when "4"
          change_password req,res,cb
        when "5"
          main_menu req,res,cb

  main_menu: (req,res,cb) ->
    res.execute 'play_and_get_digits', '1 1 1 15000 # phrase:voicemail_menu:1:2:3:4 silence_stream://250 choice \\d', (req,res) ->
      switch req.body.variable_choice
        when "1"
          new_messages req,res,cb
        when "2"
          saved_messages req,res,cb
        when "3"
          config_menu res,res,cb
        when "4"
          goodbye res

##
# The callback will receive the CouchDB database URI for the user
# and a User object instance.
#
org_couchdb_user = 'org.couchdb.user:'

locate_user = (config,req,res,number,cb,attempts) ->

  message_min_duration = config.voicemail.min_duration if config.voicemail.min_duration?
  message_max_duration = config.voicemail.max_duration if config.voicemail.max_duration?

  attempts ?= 3
  if attempts <= 0
    return goodbye res

  number_domain = config.voicemail.number_domain ? 'local'

  provisioning_db = pico config.provisioning.local_couchdb_uri
  provisioning_db.retrieve "number:#{number}@#{number_domain}", (e,r,b) ->
    if e? or not b?.user_database?
      util.log "Number #{number}@#{number_domain} not found, trying again."
      res.execute 'play_and_get_digits', "1 16 1 15000 # phrase:'voicemail_enter_id:#' phrase:'voicemail_fail_auth' destination \\d+ 3000", (req,res) ->
        return locate_user config, req, res, req.body.variable_destination, cb, attempts-1
      return

    # So we got a user document. Let's locate their user database.
    # userdb_base_uri must contain authentication elements (e.g. "voicemail" user+pass)
    db_uri = config.voicemail.userdb_base_uri + '/' + b.user_database
    cb db_uri, new User db_uri, number

exports.record = (config,req,res,username) ->

  locate_user arguments..., (db_uri,user) ->

    msg = new Message db_uri, timestamp(), req.channel_data.variable_sip_from_user, req.channel_data.variable_uuid
    msg.create req, res, (req,res) ->
      user.play_prompt req, res, (req,res)-> msg.start_recording req, res

exports.inbox = (config,req,res,username) ->

  locate_user arguments..., (db_uri,user) ->
    user.authenticate req, res, (req,res) ->
      # Enumerate messages
      user.new_messages req, res, (req,res,rows) ->
        user.navigate_messages req, res, rows, 0, (req,res) ->
          # Go to the main menu after message navigation
          user.main_menu req, res

exports.main = (config,req,res,username) ->

  locate_user arguments..., (db_uri,user) ->
    user.authenticate req, res, (req,res) ->
      # Present the main menu
      user.main_menu req, res
