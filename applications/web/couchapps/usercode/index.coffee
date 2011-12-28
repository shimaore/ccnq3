$(document).ready ->

  container = '#content'

  profile = $(container).data 'profile'
  model = $(container).data 'model'

  user_is = (role) ->
    profile.roles?.indexOf(role) >= 0

  $.sammy container, ->
    $.menu.set [
      {
        label:  'Provisioning'
        menu: [
          {
            label:  'New host'
            href:  '#/host'
          }
        ]
      }
      {
        label:  'Main'
        href:   '#/inbox'
      }
      {
        label:  'Logout'
        href:   '#/logout'
      }
    ]

    app = @

    app.run '#/inbox'
