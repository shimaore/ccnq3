###
Fill-in the "content" div.
###

client content: ->
  $(document).ready ->
    $('#content').load '/u/content.html', ->
      $.getScript('/u/login.js')
      $.getScript('/u/register.js')

get '/content.html': ->
  widget 'content'

view content: ->
  div id:'login_container'
  if @session.logged_in?
    div -> "You are currently logged in, congratulations!"
  else
    div ->
      span "Please register if you do not have access."
      div id:'register_container'
