# Zappa

client login: ->
  $(document).ready ->

    $('#login_container').load '/login.widget', ->
      $('form.main').addClass('ui-widget-content')
      $('button,input[type="submit"],input[type="reset"]').button()

      # Logout: simply clear the existing session.
      $('#logout').submit ->
        ajax_options =
          type: 'DELETE'
          url:  '/session.json'
          success: (data) ->
            if data.success is 'ok'
              window.location.reload()

        $.ajax ajax_options
        return false

      # Login button
      $('#login_window').submit ->
        $('#login').dialog('open')
        return false

      $('#login_cancel').click ->
        $('#login').dialog('close')
        return false

      # Login dialog
      $('#login').dialog({ autoOpen: false, modal: true, resizable: false })

      $('#login').submit ->
        ajax_options =
          type: 'PUT'
          url: '/login.json'
          dataType: 'json'
          data:
            username: $('#login_username').val()
            password: $('#login_password').val()
          success: (data) ->
            if data.success is 'ok'
              $('#login').dialog('close')
              window.location.reload()
            else
              $('#login_error').html('Login failed')
        $.ajax(ajax_options)
        return false

      # Register button
      $('#register_window').submit ->
        $('#register').dialog('open')
        return false

      $('#register_cancel').click ->
        $('#register').dialog('close')
        return false

      # Register dialog
      $('#register').dialog({ autoOpen: false, modal: true, resizable: false })

      $('#register').submit ->
        ajax_options =
          type: 'PUT'
          url:  '/register.json'
          dataType: 'json'
          data:
            first_name: $('#register_first_name').val()
            last_name:  $('#register_last_name').val()
            email:      $('#register_email').val()
          success: (data) ->
            if data.success is 'ok'
              $('#register').dialog('close')
              window.location.reload()
            else
              $('#register_error').html('Registration failed, try again')
        $.ajax(ajax_options)
        return false

      # Resend button
      $('#resend_window').submit ->
        $('#register').dialog('open')
        return false

      $('#resend_cancel').click ->
        $('#register').dialog('close')
        return false

      # Resend dialog
      $('#resend').dialog({ autoOpen: false, modal: true, resizable: false })

      $('#resend').submit ->
        ajax_options =
          type: 'PUT'
          url:  '/resend.json'
          dataType: 'json'
          data:
            email:      $('#resend_email').val()
          success: (data) ->
            if data.success is 'ok'
              $('#resend').dialog('close')
              window.location.reload()
            else
              $('#resend_error').html('Operation failed, try again')
        $.ajax(ajax_options)
        return false


      # Load current state
      $.getJSON '/session.json', (data) ->
        if data.user_id?
          $('#logged_in').show()
          $('#not_logged_in').hide()
        else
          $('#not_logged_in').show()
          $('#logged_in').hide()


get '/login.widget': -> widget 'login_widget'

view login_widget: ->

  l = (_id,_label,_class) ->
    label for: _id, -> _label
    if _class?
      input id: _id, name: _id, class: _class
    else
      input id: _id, name: _id

  lr = (_id,_label) -> l(_id,_label,'required')

  span id: 'logged_in' ->
    form id: 'logout', ->
      input type: 'submit', value: 'Logout'

  span id: 'not_logged_in' ->
    form id: 'login_window', ->
      input type: 'submit', value: 'Login'

    form id: 'register_window', ->
      input type: 'submit', value: 'Register'

    form id: 'resend_window', ->
      input type: 'submit', value: 'Resend password'

  form id: 'login', class: 'main validate', ->
    span id: 'login_error'
    div -> lr 'login_username', 'Username'
    div -> lr 'login_password', -> 'Password'
    div ->
      input type: 'submit', value: 'Login'
      button id: 'login_cancel', -> 'Cancel'

  form id: 'register', class: 'main validate', method: 'post', ->
    span id: 'register_error'
    div -> lr 'register_first_name', 'First Name'
    div -> lr 'register_last_name', 'Last Name'
    div -> l  'register_email', 'Email', 'required email'
    # XXX TODO Captcha
    div ->
      input type: 'submit', value: 'Register'
      button id: 'register_cancel', -> 'Cancel'

  form id: 'resend', class: 'main validate', method: 'post', ->
    span id: 'resend_error'
    div -> l  'resend_email', 'Email', 'required email'
    # XXX TODO Captcha
    div ->
      input type: 'submit', value: 'Send my password'
      button id: 'resend_cancel', -> 'Cancel'

style login: 'form#login_window, form#logout, #menu_buttons { display: inline; }'

