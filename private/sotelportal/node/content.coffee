###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###
###
Fill-in the "content" div.
###

client content: ->
  $(document).ready ->
    $('#content').load '/p/content.html', ->
      $.getScript '/u/login.js'
      $.getScript '/u/register.js'
      $.getScript '/u/recover.js'
      # Application-specific code here.
      $.getScript('/p/login.js')

get '/content.html': ->
  if not session.logged_in?
    return widget 'public'

  widget 'content'

view public: ->
  div id:'login_container'
  div id:'register_container'
  div id:'password_recovery_container'

view content: ->
  div id:'login_container'

  # Here goes the main page layout.
  div ->
    div id: 'main', ->
      'Welcome to the Sotel Portal. Great content expected here soon.'
