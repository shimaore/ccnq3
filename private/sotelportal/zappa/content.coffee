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

        # Interaction
        $.getScript('/public/js/jquery.couch.js')
        $.getScript('/public/js/jquery.deepjson.js')
        $.getScript('/public/js/jquery.couch_json.js')

        # Mark the user record as complete / get user info.
        $.getJSON '/u/profile.json', (profile) ->
          if profile.error?
            $('#log').html "Could not access your profile"
          else
            $('#log').html "Welcome #{profile.name}."
            session.profile = profile
            # Load the applications
            $.getScript('/p/partner_signup.js')


  get '/p/content.html': ->
    @confirmed = 'confirmed' in session.roles
    @partner = 'partner' in session.roles
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
    h3 id:'log'

    # Here goes the main page layout.
    div ->
      div id: 'main', ->
        'You are now successfully logged into the SoTel Systems Online Portal. More content and features are expected here soon.'

    if not @partner
      div id:'partner_signup_trigger', -> 'Become a SoTel Systems partner!'
