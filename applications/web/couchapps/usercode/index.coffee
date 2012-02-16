$(document).ready ->

  container = '#content'

  profile = $(container).data 'profile'
  model = $(container).data 'model'

  user_is = (role) ->
    profile.roles?.indexOf(role) >= 0

  $.sammy container, ->

    $('#menu_container').html do $.compile_template ->
      ul id:'menu', ->
        li -> a href:'#/inbox', 'Main'
        li -> a href:'#/logout', 'Logout'
        li ->
          span 'Provisioning'
          ul ->
            li -> a href:'#/host', 'New host'
            li -> a href:'#/endpoint', 'New endpoint'

    app = @

    app.run '#/inbox'
