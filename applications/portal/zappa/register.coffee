###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

@include = ->

  cdb = require 'cdb'

  config = null
  require('ccnq3_config').get (c) ->
    config = c

  @coffee '/u/register.js': ->
    $(document).ready ->
      $('#register_container').load '/u/register.widget', ->

        $('#register-message').dialog
          autoOpen: false
          modal: true
          resizable: false
          buttons:
            'OK': ->
              $(@).dialog('close')
          close: ->
              window.location.reload()

        $('form.main').addClass('ui-widget-content')
        $('form.validate').validate()
        $('button,input[type="submit"],input[type="reset"]').button()

        $('#register').submit ->
          $('#register_error').html("")
          ajax_options =
            type: 'PUT'
            url: '/u/register.json'
            data: $('#register').serialize()
            dataType: 'json'
            success: (data) ->
              if data.ok
                $('#register-message-email').html data.username
                $('#register-message-domain').html data.domain
                $('#register-message').dialog 'open'
              else
                if data.error is 409
                  $('#register_error').html("You have already registered with this email address. Would you like to Sign In or do you need your password Recovered?")
                else
                  $('#register_error').html("Account creation failed: #{data.error}")
          $.ajax(ajax_options)
          return false

  @get '/u/register.widget': ->
    local_part = config.mail_password.sender_local_part
    @render 'register_widget', local_part: local_part, layout:no

  crypto = require 'crypto'
  uuid = require 'node-uuid'

  @put '/u/register.json': ->

    name = @request.param 'name'
    email = @request.param 'email'
    if not name or not email
      return @send error:'Invalid parameters, try again'

    profile = @body
    for k,v of profile when k.match /^_/
      delete profile[k]

    # Currently assumes username = email
    username = email
    db = cdb.new config.users.couchdb_uri
    db.exists (it_does) =>
      if not it_does
        return @send error:'Not connected to the database'

      p =
        _id: 'org.couchdb.user:'+username
        type: 'user'
        name: username
        roles: []
        domain: @request.header('Host')
        profile: profile
        user_database: 'u'+uuid() # User's database UUID (or UUID prefix)
        send_password: true # send them their new password

      # PUT without _rev can only happen once
      db.put p, (r) =>
        if r.error?
          return @send r
        else
          if config.users.logged_in_after_initial_registration
            @session.logged_in = username
            @session.roles     = []
          return @send ok:true, username:p.name, domain:p.domain

  @view register_widget: ->

    l = (_id,_label,_class) ->
      label for: _id, -> _label
      if _class?
        input name: _id, class: _class
      else
        input name: _id

    div id:"register-message", title:"Registration complete", =>
      h2 -> 'Thank you...'
      p =>
        """
        For your security and protection, we need you to validate the email address you entered.
        Please check your inbox at
        <span id="register-message-email"></span>
        for a message from #{@local_part}@<span id="register-message-domain"></span>
        with your automatically created password.
        Then you will want to return to our portal home page to log in.
        """

    form id: 'register', class: 'main validate', method: 'post', title: 'Account creation', ->
      span id: 'register_error', class: 'error'
      input type: 'hidden', name: '_method', value: 'PUT'
      div -> l  'name', 'Name', 'required minlength(2)'
      div -> l  'email', 'Email', 'required email'
      div -> l  'phone', 'Phone', 'required phone'

      # XXX TODO Captcha
      div ->
        input type: 'submit', value: 'Create Account'
