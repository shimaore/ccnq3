###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

@include = ->
  cdb = require 'cdb'
  url = require 'url'
  querystring = require 'querystring'

  @coffee '/u/recover.js': ->
    $(document).ready ->

      $('#password_recovery_container').load '/u/recover.widget', ->
        $('#recover_buttons').buttonset()
        $('form.main').addClass('ui-widget-content')
        $('form.validate').validate()
        $('button,input[type="submit"],input[type="reset"]').button()

        $('#recover').dialog({ autoOpen: false, modal: true, resizable: false })

        $('#recover_window').submit ->
          $('#recover').dialog('open')
          return false

        $('#cancel_recover').click ->
          $('#recover').dialog('close')
          return false

        $('#recover').submit ->
          ajax_options =
            type: 'post'
            url: '/u/recover.json'
            data:
              email: $('#recover_email').val()
            dataType: 'json'
            success: (data) ->
              if not data.ok
                $('#recover_error').html('Operation failed')
              else
                $('#login_error').html('')
                $('#login').dialog('close')
                window.location.reload()

          $('#recover_error').html("")
          $.ajax(ajax_options)

          return false


  @get '/u/recover.widget': -> @render 'recover_widget', layout:no

  @view recover_widget: ->

    div id: 'recover_buttons', ->
      form id: 'recover_window', ->
        input type: 'submit', value: 'Recover password'

    form id: 'recover', class: 'main validate', method: 'get', ->
      span id: 'recover_error', class: 'error'
      div ->
        label for: 'recover_email', -> 'Email'
        input id: 'recover_email', name: 'email'
      # XXX Captcha
      div ->
        input type: 'submit', value: 'Confirm'

  @post '/u/recover.json': ->
    email = @req.param 'email'
    if not email?
      return @send {error:'Missing username'}

    users_cdb = cdb.new config.users.couchdb_uri
    users_cdb.get "org.couchdb.user:#{email}", (p) =>
      if p.error?
        return @send error: 'Please make sure you register first.'

      # Everything is OK
      p.send_password = true
      users_cdb.put p, (r) ->
        if r.error?
          return @send r
        else
          return @send ok:true
