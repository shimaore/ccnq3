###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

client login: ->
  $(document).ready ->

    $('#login_container').load '/u/login.widget', ->
      $('#menu_buttons').buttonset()
      $('form.main').addClass('ui-widget-content')
      $('button,input[type="submit"],input[type="reset"]').button()

      $('#login').dialog({ autoOpen: false, modal: true, resizable: false })

      $('#login_window').submit ->
        $('#login').dialog('open')
        return false

      $('#cancel_login').click ->
        $('#login').dialog('close')
        return false

      $('#login').submit ->
        ajax_options =
          url: '/u/login.json'
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

      $('#logout').submit ->
        ajax_options =
          url: '/logout.json'
          success: (data) ->
            if data.success?
              window.location.reload()
        $.ajax(ajax_options)
        return false

get '/login.widget': -> widget 'login_widget'

view login_widget: ->

  div id: 'menu_buttons', ->
    if @session.logged_in?
      a href: '/profile/', -> @session.logged_in
      form id: 'logout', ->
        input type: 'submit', value: 'Logout'
    else
      form id: 'login_window', ->
        input type: 'submit', value: 'Login'

  form id: 'login', class: 'main validate', ->
    span id: 'login_error'
    div ->
      label for: 'login_username', -> 'Username'
      input id: 'login_username', class: 'required'
    div ->
      label for: 'login_password', -> 'Password'
      input type: 'password', id: 'login_password', class: 'required'
    div ->
      input type: 'submit', value: 'Login'
      button id: 'cancel_login', -> 'Cancel'

get '/login.json': ->
  if not @username? and not @password?
    return send {error:'Missing parameters'}

  db = portal_cdb
  db.get @username, (p) =>
    if p.error? or p.password isnt @password
      return send {error:'Invalid password'}
    session.logged_in = @username
    send 'success', 'ok'

get '/logout.json': ->
  delete session.logged_in
  send 'success', 'ok'

