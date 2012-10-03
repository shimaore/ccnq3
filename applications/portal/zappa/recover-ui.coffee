###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

@include = ->

  @coffee '/ccnq3/portal/recover.js': ->
    $(document).ready ->

      $('#password_recovery_container').load '/ccnq3/portal/recover.widget', ->
        $('#recover_buttons').buttonset()
        $('form.main').addClass('ui-widget-content')
        $('form.validate').validate()
        $('button,input[type="submit"],input[type="reset"]').button()

        $('#recover').dialog({ autoOpen: false, modal: true, resizable: false })

        $('#recover_window').submit (e)->
          $('#recover').dialog('open')
          return false

        $('#cancel_recover').click ->
          $('#recover').dialog('close')
          return false

        $('#recover').submit ->
          $('#recover_error').html('')
          ee = $.ccnq3.portal.recover $('#recover_email').val()
          ee.on 'error', ->
            $('#recover_error').html('Operation failed')
          ee.on 'success', ->
            $('#recover').dialog('close')
          return false


  @get '/ccnq3/portal/recover.widget': -> @render 'recover_widget', layout:no

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
