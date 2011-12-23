$(document).ready ->

  container = '#content'

  profile = $(container).data 'profile'
  model = $(container).data 'model'

  user_is = (role) ->
    profile.roles?.indexOf(role) >= 0

  $.sammy container, ->
    app = @

    app.run '#/inbox'
