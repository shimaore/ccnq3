###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###
###
Fill-in the "content" div.
###

@include = ->
  @coffee '/u/content.js': ->
    $(document).ready ->

      container = '#content'

      # Mark the user record as complete / get user info.
      $.getJSON '/u/profile.json', (profile) =>
        if profile.user_database?
          $(container).data 'profile', profile
          $(container).load "/#{profile.user_database}/_design/portal/index.html"
        else
          $.getScript '/u/login.js'
          $.getScript '/u/register.js'
          $.getScript '/u/recover.js'
          $.getScript '/roles/login.js', ->
            # Application-specific code here.
            $.getScript '/login.js'
