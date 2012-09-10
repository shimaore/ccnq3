###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###
###
Fill-in the "content" div.
###

@include = ->
  @coffee '/ccnq3/portal/content.js': ->
    $(document).ready ->

      container = '#content'

      # Mark the user record as complete / get user info.
      $.getJSON '/ccnq3/portal/profile.json', (profile) =>
        if profile.user_database?
          $(container).data 'login_profile', profile
          $.getScript "/#{profile.user_database}/_design/portal/index.js"
        else
          for name in ['login', 'register', 'recover']
            $.getScript "/ccnq3/portal/#{name}.js"
          $.getScript '/ccnq3/roles/login.js', ->
            # Application-specific code here.
            $.getScript '/login.js'
