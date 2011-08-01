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
  widget 'content'

view content: ->
  div id:'login_container'
  if not @session.logged_in?
    return div ->
      span "Please create an account if you do not have access."
      div id:'register_container'
      div id:'password_recovery_container'

  div -> "You are currently signed in, congratulations!"
