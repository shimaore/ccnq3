# messaging.coffee
# (c) 2012 Stephane Alnet
# License: AGPL3+

util = require 'util'
request = require 'request'
nano = require 'nano'

hangup = (req,res) -> res.hangup()

timestamp = -> new Date().toJSON()

##
# Message "part" (segments/fragments) are numbered out from 1.
the_first_part = 1

class Message

  ##
  # new Message db_uri, _id
  # new Message db_uri, timestamp, caller_id
  constructor: (@db_uri,timestamp,caller_id) ->
    if not @caller_id?
      @id = timestamp
    else
      @timestamp = timestamp
      @caller_id = caller_id
      @id = 'voicemail:' + timestamp + caller_id
    @msg_uri = @db_uri + '/' + qs.escape(@id)
    @db = nano @db_uri
    @part = the_first_part

  # Record the current part
  start_recording: (req,res,cb) ->
    cb ?= (req,res) -> @post_recording req,res
    request.head @msg_uri, (r) =>
      # Play beep to indicate we are ready to record
      res.execute 'tone', XXX, (req,res) =>
        min_duration = config.voicemail.min_duration ? 5   # FIXME default_voicemail_min_duration
        max_duration = config.voicemail.max_duration ? 300 # FIXME default_voicemail_max_duration
        res.execute 'record', "{RECORD_WRITE_ONLY=true,record_min_sec=#{min_duration}}#{@msg_uri}/part#{@part}.wav?rev=#{r._rev} #{max_duration}", cb

  # Delete parts
  delete_parts: (cb) ->
    @db.get @id, (e,b,h) ->
      # Remove all attachments
      b._attachments = {}
      @db.insert b, cb

  # Post-recording menu
  post_recording: (req,res) ->
    # Check whether the attachment exists (it might be deleted if it doesn't match the minimum duration)
    request.head "#{@msg_uri}/part#{@part}.wav", (error,content) ->
      if error?
        res.execute 'phrase', "could not record please try again", (req,res) ->
          @start_recording req, res
        return

      res.execute 'play_and_get_digits', "1 1 1 3000 phrase:'to-start-over to-listen to-append to-finish,1234' phrase:'invalid choice' choice \\d 3000", (req,res) ->
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
            res.execute 'phrase', 'goodbye', hangup

  # Play the parts one after the other; when the last part is played, call the optional callback
  listen_recording: (req,res,this_part,cb) ->
    cb ?= (req,res) -> @post_recording req,res
    request.head "#{@msg_uri}/part#{this_part}.wav", (error,content) ->
      if error
        # Presumably we've read all the parts
        return cb req, res
      else
        res.execute 'playback', "#{msg_uri}/part#{this_part}.wav", (req,res) ->
          listen_recording req, res, this_part+1, cb

  # Play the message enveloppe
  play_envelope: (req,res,cb) ->
    @db.get @id, (e,b,h) ->
      res.execute 'play_and_get_digits', "1 1 1 1000 phrase:'message received,#{b.timestamp}' silence_stream://250 choice \\d 1000", (req,res) ->
        if req.body.variable_choice
          cb req, res, req.body.variable_choice
        else
          cb req, res

  # Play a recording, calling the callback with an optional collected digit
  play_recording: (req,res,this_part,cb) ->
    request.head "#{@msg_uri}/part#{this_part}.wav", (error,content) ->
      if error
        cb req, res
      else
        res.execute 'play_and_get_digits', "1 1 1 1000 #{msg_uri}/part#{this_part}.wav silence_stream://250 choice \\d 1000", (req,res) ->
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
      # FIXME Add more VM metadata such as caller-id, ..

    # Create new CDB record to hold the voicemail metadata
    @db.insert msg, (e,b,h) ->
      if e
        util.log "Could not create #{msg_uri}"
        res.execute 'phrase', "could not record message", hangup
        return
      cb req,res


class User

  constructor: (@db_uri,@user) ->
    @user_db = nano @db_uri

  voicemail_settings: (req,res,cb) ->
    # Memoize
    if @vm_settings
      return cb @vm_settings

    @user_db.get 'voicemail_settings', (e,vm_settings,h) =>
      if e
        util.log "VM Box for #{@user} is not available: #{e}"
        res.execute 'phrase', 'vmbox is not available', hangup
      else
        @vm_settings = vm_settings # Memoize
        cb vm_settings

  play_prompt: (req,res,cb) ->
    @voicemail_settings req, res, (vm_settings) ->
      if vm_settings._attachments["prompt.wav"]
        res.execute 'playback', @db_uri + '/voicemail_settings/prompt.wav', cb

      else if vm_settings._attachments["name.wav"]
        res.execute 'phrase', "please leave a message for,#{@db_uri}/voicemail_settings/name.wav", cb

      else
        res.execute 'phrase', "please leave a message for,#{@user}", cb

  authenticate: (req,res,cb,attempts) ->
    attempts ?= 3
    if attempts <= 0
      res.execute 'phrase', 'goodbye', hangup
      return

    @voicemail_settings req, res, (vm_settings) ->
      if vm_settings.no_pin
        return do cb

      if vm_settings.pin?
        res.execute 'play_and_get_digits', "4 10 1 3000 phrase:'please enter your pin' phrase:'invalid entry' pin \\d+ 3000", (req,res) ->
          if req.body.variable_pin is vm_settings.pin
            do cb
          else
            @authenticate res,cb, attempts-1

  new_messages: (res,cb) ->
    @user_db.view 'voicemail', 'new_messages', (e,b,h) ->
      if e
        cb null, res
      res.execute 'phrase', "you have new messages,#{b.total_rows}", (req,res) -> cb req, res, r.rows

  navigate_messages: (req,res,rows,current,cb) ->
    # Exit once we reach the end or there are no messages, etc.
    if current < 0 or current >= rows.length
      cb req, res

    navigate = (req,res,key) ->
      switch key
        when "1"
          if current is 0
            res.execute 'phrase', 'no previous message', (req,res)->
              @navigate_messages req, res, rows, current, cb
          else
            @navigate_messages req, res, rows, current-1, cb

    msg = new Message @db_uri, rows[current]._id
    msg.play_enveloppe (req,res,choice) ->
      if choice?
        navigate req, res, choice
      else
        # Default navigation is: read next message
        @navigate_messages req, res, rows, current+1, cb

##
# The callback will receive the CouchDB database URI for the user
# and a User object instance.
#
org_couchdb_user = 'org.couchdb.user:'

locate_user = (config,res,username,cb) ->

  users_db = nano config.voicemail.users_couchdb_uri
  users_db.get org_couchdb_user+username, (r) ->
    if r.error?
      util.log "User #{username} not found, trying again."
      res.execute 'play_and_get_digits', "1 16 1 3000 # phrase:'destination please' phrase:'invalid number' destination \\d+ 3000", (req,res) ->
        # FIXME restrict the number of attempts in a single call
        return locate_user config, res, req.body.variable_destination, cb

    # So we got a user document. Let's locate their user database.
    # userdb_base_uri should contain authentication elements (e.g. "voicemail" user+pass)
    db_uri = config.voicemail.userdb_base_uri + r.user_database
    cb db_uri, new User db_uri, username

exports.record = (config,res,username) ->

  locate_user arguments..., (db_uri,user) ->

    msg = new Message db_uri, timestamp(), caller_id
    msg.create null, res, ->
      user.play_prompt res, -> msg.start_recording null, res

exports.inbox = (config,res,username) ->

  locate_user arguments..., (db_uri,user) ->
    user.authenticate res, (req,res) ->
      # Enumerate messages
      user.new_messages res, (req,res,rows) ->
        user.navigate_messages req, res, rows, 0, (req,res) ->
          # Go to the main menu after message navigation
          user.main_menu req, res

exports.main = (config,res,username) ->

  locate_user arguments..., (db_uri,user) ->
    user.authenticate res, (req,res) ->
      # Present the main menu
      user.main_menu req, res
