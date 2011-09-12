###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###
###
Fill-in the "content" div.
###

@include = ->
  coffee '/p/content.js': ->
    $(document).ready ->
      $('#content').load '/p/content.html', ->
        $.getScript '/u/login.js'
        $.getScript '/u/register.js'
        $.getScript '/u/recover.js'
        # Application-specific code here.
        $.getScript('/roles/login.js')
        $.getScript('/p/login.js')

        # Mark the user record as complete / get user info.
        $.getJSON '/u/profile.json', (data) ->
          if data.error?
            $('#log').html "Could not access your profile"
          else
            $('#log').html "Welcome #{data.name}."

  get '/p/content.html': ->
    if session.logged_in?
      render 'content', layout:no
    else
      render 'public', layout:no

  view public: ->
    div id:'login_container'
    div id:'register_container'
    div id:'password_recovery_container'

  view content: ->
    div id:'login_container'
    div id:'log'

    # Here goes the main page layout.
    div ->
      div id: 'main', ->
        'Welcome to the Sotel Portal. Great content expected here soon.'
