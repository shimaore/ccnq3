###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

# Load CouchDB
cdb = require 'cdb'

def cdb: cdb

using 'url'
using 'querystring'

client recover: ->
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

        $('#recover_error').html("")
        $.ajax(ajax_options)

        return false


get '/recover.widget': -> widget 'recover_widget'

view recover_widget: ->

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

post '/recover.json': ->
  if not @email?
    return send {error:'Missing username'}

  users_cdb = cdb.new config.confirm.users_couchdb_uri
  users_cdb.get "org.couchdb.user:#{@email}", (p) =>
    if p.error?
      return send error: p.error

    if p.status isnt 'confirmed'
      return send error: 'Invalid request.'

    # Everything is OK
    p.send_password = true
    users_cdb.put p, (r) ->
      if r.error?
        return send r
      else
        return send ok:true
