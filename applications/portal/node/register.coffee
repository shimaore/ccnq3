###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

# Content

client register: ->
  $(document).ready ->
    $('#register_container').load '/u/register.widget', ->

      $('#register_buttons').buttonset()
      $('form.main').addClass('ui-widget-content')
      $('form.validate').validate()
      $('button,input[type="submit"],input[type="reset"]').button()

      $('#register').dialog({ autoOpen: false, modal: true, resizable: false })

      $('#register_window').submit ->
        $('#register').dialog('open')
        return false

      $('#cancel_register').click ->
        $('#register').dialog('close')
        return false

      $('#register').submit ->
        $('#register_error').html("")
        ajax_options =
          type: 'PUT'
          url: '/u/register.json'
          data: $('#register').serialize()
          dataType: 'json'
          success: (data) ->
            if data.ok
              $('#register').dialog('close')
              window.location.reload()
            else
              $('#register_error').html("Account creation failed: #{data.error}")
        $.ajax(ajax_options)
        return false

# HTML

get '/register.widget': -> widget 'register_widget'

using 'crypto'

put '/register.json': ->

  if not @first_name or not @last_name or not @email
    return error 'Invalid parameters, try again'

  # Currently assumes username = email
  username = @email
  db = cdb.new config.register.users_couchdb_uri
  db.exists (it_does) =>
    if not it_does
      return send error:'Not connected to the database'

    p =
      _id: 'org.couchdb.user:'+username
      type: 'user'
      name: username
      roles: []
      domain: request.header('Host')
      confirmation_code: crypto.createHash('sha1').update("a"+Math.random()).digest('hex')
      confirmation_expires: (new Date()).valueOf() + 2*24*3600*1000
      status: 'send_confirmation'
      profile: params
      access: {} # source: [prefix,..], ..
      update: {} # source|application: [prefix,..], ..

    # PUT without _rev can only happen once
    db.put p, (r) ->
      if r.error?
        return send r
      else
        return send ok:true

view register_widget: ->

  l = (_id,_label,_class) ->
    label for: _id, -> _label
    if _class?
      input name: _id, class: _class
    else
      input name: _id

  lr = (_id,_label) -> l(_id,_label,'required')

  div id: 'register_buttons', ->
    form id: 'register_window', ->
      input type: 'submit', value: 'Create Account'

  form id: 'register', class: 'main validate', method: 'post', title: 'Account creation', ->
    span id: 'register_error', class: 'error'
    input type: 'hidden', name: '_method', value: 'PUT'
    div -> l  'first_name', 'First Name', 'required minlength(2)'
    div -> l  'last_name', 'Last Name', 'required minlength(2)'
    div -> l  'email', 'Email', 'required email'
    div -> l  'phone', 'Phone', 'required phone'

    # XXX TODO Captcha
    div ->
      input type: 'submit', value: 'Create Account'
      button id: 'cancel_register', -> 'Cancel'

