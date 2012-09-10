###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

@include = ->

  config = null
  require('ccnq3_config') (c) ->
    config = c

  @coffee '/ccnq3/portal/login.js': ->
    $(document).ready ->

      $('#login_container').load '/ccnq3/portal/login.widget', ->
        $('form.main').addClass('ui-widget-content')
        $('form.validate').validate()
        $('button,input[type="submit"],input[type="reset"]').button()

        $('#login').submit ->
          ee = $.ccnq3.portal.login $('#login_username').val(), $('#login_password').val()
          ee.on 'notify', (text) ->
            $('#login_error').html(text)
          ee.on 'success', ->
            $('#login_error').html('')
            $('#login').dialog('close')
            window.location.reload()
          return false

        $('#logout').submit ->
          ee = $.ccnq3.portal.logout()
          ee.on 'success', ->
            window.location.reload()
          return false

  @get '/ccnq3/portal/login.widget': ->
    if @session.logged_in?
      @render 'logout_widget', layout:no
    else
      @render 'login_widget', layout:no

  @view logout_widget: ->

        form id: 'logout', ->
          input type: 'submit', value: 'Logout'

  @view login_widget: ->

        form id: 'login', class: 'main validate', title: 'Sign in', ->
          span id: 'login_error', class: 'error'
          div ->
            label for: 'login_username', -> 'Username'
            input id: 'login_username', class: 'required'
          div ->
            label for: 'login_password', -> 'Password'
            input type: 'password', id: 'login_password', class: 'required'
          div ->
          input type: 'submit', value: 'Sign in'

