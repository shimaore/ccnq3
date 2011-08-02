###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

client register: ->
  $(document).ready ->
    $('#register_container').load '/u/register.widget', ->

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
              window.location.reload()
            else
              $('#register_error').html("Account creation failed: #{data.error}")
        $.ajax(ajax_options)
        return false

get '/register.widget': -> partial 'register_widget'

using 'crypto'

put '/register.json': ->

  if not @first_name or not @last_name or not @email
    return error 'Invalid parameters, try again'

  for k,v of params when k.match /^_/
    delete params[k]

  # Currently assumes username = email
  username = @email
  db = cdb.new config.users.couchdb_uri
  db.exists (it_does) =>
    if not it_does
      return send error:'Not connected to the database'

    p =
      _id: 'org.couchdb.user:'+username
      type: 'user'
      name: username
      roles: []
      domain: request.header('Host')
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

