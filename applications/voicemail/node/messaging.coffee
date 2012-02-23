# messaging.coffee
# (c) 2012 Stephane Alnet
# License: AGPL3+

util = require 'util'
pico = require 'pico'
request = require 'request'

fs = require 'fs'
child_process = require 'child_process'

hangup = (call) -> call.hangup()

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

goodbye = (call) ->
  call.command 'phrase', 'voicemail_goodbye', hangup

##
# Message "part" (segments/fragments) are numbered out from 1.
the_first_part = 1

message_min_duration = 5
message_max_duration = 300
message_format = 'wav'
message_streaming = false

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
  start_recording: (call,cb) ->
    cb ?= (call) => @post_recording call
    @db.rev @id, (e,r,b) =>
      if not b?.rev?
        util.log "start_recording: Missing document #{@id}"
        # FIXME notify the user
        return

      fifo_path = "/tmp/#{@id}.#{message_format}"
      upload_url = "#{@msg_uri}/part#{@part}.#{message_format}?rev=#{b.rev}"
      fifo_stream = null

      if message_streaming
        preprocess = (cb) ->
          child_process.exec "/usr/bin/mkfifo -m 0660 '#{fifo_path}'", (error) ->
            if error?
              util.log "start_recording: Could not mkfifo"
              # FIXME notify the user
              return

            # Start the proxy on the fifo
            fifo_stream = fs.createReadStream(fifo_path).pipe request.put upload_url
            do cb
        postprocess = (cb) -> do cb
      else
        preprocess = (cb) -> do cb
        postprocess = (cb) ->
          # Upload the file
          fifo_stream = fs.createReadStream(fifo_path).pipe request.put upload_url
          do cb

      recurse = -> @start_recording call, cb

      preprocess =>
        # Play beep to indicate we are ready to record
        call.command 'set', 'RECORD_WRITE_ONLY=true', (call) ->
          call.command 'set', 'playback_terminators=#1234567890', (call) ->
            call.command 'gentones', '%(500,0,800)', (call) ->

              call.command 'record', "#{fifo_path} #{message_max_duration} 20 3", (call) ->
                # The DTMF that was pressed is available in call.body.playback_terminator_used

                # FIXME save "call.body.variable_record_seconds" somewhere

                postprocess ->

                  fifo_stream.on 'close', ->
                    if call.body.variable_record_seconds < message_min_duration
                      request.del upload_url

                    # Remove the FIFO/file
                    fs.unlink fifo_path, ->
                      cb call

                  fifo_stream.on 'error', ->
                    # FIXME Remove the attachment from the database?
                    # request.del upload_url
                    # Remove the FIFO/file
                    fs.unlink fifo_path, =>
                      # FIXME notify the user that they should retry
                      do recurse

  # Delete parts
  delete_parts: (cb) ->
    @db.retrieve @id, (e,r,b) ->
      # Remove all attachments
      b._attachments = {}
      @db.update b, cb

  # Post-recording menu
  post_recording: (call) ->
    # Check whether the attachment exists (it might be deleted if it doesn't match the minimum duration)
    request.head "#{@msg_uri}/part#{@part}.#{message_format}", (e) ->
      if e?
        call.command 'phrase', "could not record please try again", (call) ->
          @start_recording call
        return

      call.command 'play_and_get_digits', "1 1 1 15000 # phrase:'to-start-over to-listen to-append to-finish:1234' phrase:'invalid choice' choice \\d 3000", (call) ->
        switch call.body.variable_choice
          when "1"
            @delete_parts ->
              @part = the_first_part
              @start_recording call
          when "2"
            @listen_recording call, the_first_part
          when "3"
            @part++
            @start_recording call
          else
            goodbye call

  # Play the parts one after the other; when the last part is played, call the optional callback
  listen_recording: (call,this_part,cb) ->
    cb ?= (call) -> @post_recording call
    request.head "#{@msg_uri}/part#{this_part}.#{message_format}", (error) ->
      if error
        # Presumably we've read all the parts
        return cb call
      else
        call.command 'playback', "#{@msg_uri}/part#{this_part}.#{message_format}", (call) ->
          @listen_recording call, this_part+1, cb

  # Play the message enveloppe
  play_enveloppe: (call,index,cb) ->
    @db.retrieve @id, (e,r,b) =>
      if e or not b?
        util.log "play_enveloppe: Missing #{@id}"
        return
      call.command 'play_and_get_digits', "1 1 1 1000 # phrase:'message received:#{index+1}:#{b.caller_id}:#{b.timestamp}' silence_stream://250 choice \\d 1000", (call) ->
        if call.body.variable_choice
          cb call, call.body.variable_choice
        else
          cb call

  # Play a recording, calling the callback with an optional collected digit
  play_recording: (call,this_part,cb) ->
    request.head "#{@msg_uri}/part#{this_part}.#{message_format}", (error) ->
      if error
        cb call
      else
        call.command 'play_and_get_digits', "1 1 1 1000 # #{msg_uri}/part#{this_part}.#{message_format} silence_stream://250 choice \\d 1000", (call) ->
          if call.body.variable_choice
            # Act on user interaction
            cb call, call.body.variable_choice
          else
            # Keep playing
            play_recording call, this_part+1, cb

  # Create a new voicemail record in the database
  create: (call,cb) ->
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
        call.command 'phrase', "sorry", hangup
        return
      cb call


class User

  constructor: (@db_uri,@user) ->
    @user_db = pico @db_uri

  voicemail_settings: (call,cb) ->
    # Memoize
    if @vm_settings?
      return cb @vm_settings

    @user_db.retrieve 'voicemail_settings', (e,r,vm_settings) =>
      if e
        util.log "VM Box for #{@user} is not available from #{@db_uri}."
        call.command 'phrase', 'vm_say:sorry', hangup
        return
      else
        @vm_settings = vm_settings # Memoize
        cb vm_settings

  play_prompt: (call,cb) ->
    @voicemail_settings call, (vm_settings) ->
      if vm_settings._attachments?["prompt.#{message_format}"]
        call.command 'playback', @db_uri + "/voicemail_settings/prompt.#{message_format}", cb

      else if vm_settings._attachments?["name.#{message_format}"]
        call.command 'phrase', "voicemail_record_message,#{@db_uri}/voicemail_settings/name.#{message_format}", cb

      else
        call.command 'phrase', "voicemail_record_message,#{@user}", cb

  authenticate: (call,cb,attempts) ->
    attempts ?= 3
    if attempts <= 0
      return goodbye call

    @voicemail_settings call, (vm_settings) ->
      wrap_cb = ->
        if vm_settings.language?
          call.command 'set',  "language=#{vm_settings.language}", (call) ->
            call.command 'phrase', 'voicemail_hello', cb
        else
          call.command 'phrase', 'voicemail_hello', cb

      if vm_settings.pin?
        call.command 'play_and_get_digits', "4 10 1 15000 # phrase:'voicemail_enter_pass:#' phrase:'voicemail_fail_auth' pin \\d+ 3000", (call) ->
          if call.body.variable_pin is vm_settings.pin
            do wrap_cb
          else
            @authenticate call, cb, attempts-1
      else
        do wrap_cb

  new_messages: (call,cb) ->
    @user_db.view 'voicemail', 'new_messages', (e,r,b) ->
      if e
        return cb call
      call.command 'phrase', "voicemail_message_count,#{b.total_rows}:new", (call) -> cb call, b.rows

  saved_messages: (call,cb) ->
    @user_db.view 'voicemail', 'saved_messages', (e,r,b) ->
      if e
        return cb call
      call.command 'phrase', "voicemail_message_count,#{b.total_rows}:saved", (call) -> cb call, b.rows

  navigate_messages: (call,rows,current,cb) ->
    # Exit once we reach the end or there are no messages, etc.
    if current < 0 or not rows? or current >= rows.length
      return cb call

    navigate = (call,key) ->
      switch key
        when "1"
          if current is 0
            call.command 'phrase', 'no previous message', (call)->
              @navigate_messages call, rows, current, cb
            return
          @navigate_messages call, rows, current-1, cb

        when "2"
          if current is rows.length-1
            call.command 'phrase', 'no next message', (call)->
              @navigate_messages call, rows, current, cb
          @navigate_messages call, rows, current+1, cb

    msg = new Message @db_uri, rows[current].id
    msg.play_enveloppe call, current, (call,choice) =>
      if choice?
        navigate call, choice
      else
        # Default navigation is: read next message
        @navigate_messages call, rows, current+1, cb

  config_menu: (call,cb) ->
    call.command 'play_and_get_digits', '1 1 1 15000 # phrase:voicemail_config_menu:1:2:3:4:5 silence_stream://250 choice \\d', (call) ->
      switch call.body.variable_choice
        when "1"
          @record_greetings call,cb
        when "2"
          @choose_greetings call,cb
        when "3"
          @choose_name call,cb
        when "4"
          @change_password call,cb
        when "5"
          @main_menu call,cb

  main_menu: (call,cb) ->
    call.command 'play_and_get_digits', '1 1 1 15000 # phrase:voicemail_menu:1:2:3:4 silence_stream://250 choice \\d', (call) ->
      switch call.body.variable_choice
        when "1"
          @new_messages call,cb
        when "2"
          @saved_messages call,cb
        when "3"
          @config_menu call,cb
        when "4"
          goodbye call

##
# The callback will receive the CouchDB database URI for the user
# and a User object instance.
#
org_couchdb_user = 'org.couchdb.user:'

locate_user = (config,call,number,cb,attempts) ->

  message_min_duration = config.voicemail.min_duration if config.voicemail.min_duration?
  message_max_duration = config.voicemail.max_duration if config.voicemail.max_duration?

  attempts ?= 3
  if attempts <= 0
    return goodbye call

  number_domain = config.voicemail.number_domain ? 'local'

  provisioning_db = pico config.provisioning.local_couchdb_uri
  provisioning_db.retrieve "number:#{number}@#{number_domain}", (e,r,b) ->
    if e? or not b?.user_database?
      util.log "Number #{number}@#{number_domain} not found, trying again."
      call.command 'play_and_get_digits', "1 16 1 15000 # phrase:'voicemail_enter_id:#' phrase:'voicemail_fail_auth' destination \\d+ 3000", (call) ->
        return locate_user config, call, call.body.variable_destination, cb, attempts-1
      return

    # So we got a user document. Let's locate their user database.
    # userdb_base_uri must contain authentication elements (e.g. "voicemail" user+pass)
    db_uri = config.voicemail.userdb_base_uri + '/' + b.user_database
    cb db_uri, new User db_uri, number

exports.record = (config,call,username) ->

  locate_user arguments..., (db_uri,user) ->

    msg = new Message db_uri, timestamp(), call.body.variable_sip_from_user, call.body.variable_uuid
    msg.create call, ->
      user.play_prompt call, -> msg.start_recording call

exports.inbox = (config,call,username) ->

  locate_user arguments..., (db_uri,user) ->
    user.authenticate call, ->
      # Enumerate messages
      user.new_messages call, (call,rows) ->
        user.navigate_messages call, rows, 0, ->
          # Go to the main menu after message navigation
          user.main_menu call

exports.main = (config,call,username) ->

  locate_user arguments..., (db_uri,user) ->
    user.authenticate call, ->
      # Present the main menu
      user.main_menu call
