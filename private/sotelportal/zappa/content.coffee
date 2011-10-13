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

      container = '#content'

      # Mark the user record as complete / get user info.
      $.getJSON '/u/profile.json', (profile) =>
        if profile.user_database?
          $(container).load "/#{profile.user_database}/_design/sotel_portal/index.js"
        else
          $(container).load '/p/content.html', ->

            $.getScript '/u/login.js'
            $.getScript '/u/register.js'
            $.getScript '/u/recover.js'
            # Application-specific code here.
            $.getScript('/roles/login.js')
            $.getScript('/p/login.js')


  get '/p/content.html': ->
    render 'public', layout:no

  view public: ->
    div class:'grid_6', ->
      div id:'login_container'
      div id:'password_recovery_container'
    div id:'register_container', class:'grid_6'
