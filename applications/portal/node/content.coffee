###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###
###
Fill-in the "content" div.
###

client content: ->
  $(document).ready ->
    $('#content').load '/u/content.html', ->
      $.getScript '/u/login.js'
      $.getScript '/u/register.js'
      $.getScript '/u/recover.js'

get '/content.html': ->
  widget  if session.logged_in? then 'content' else 'public'

view public: ->
  div id:'login_container'
  div id:'register_container'
  div id:'password_recovery_container'

view content: ->
  div -> "You are currently signed in, congratulations!"
