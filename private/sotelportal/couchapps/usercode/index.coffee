$(document).ready ->

  container = '#content'

  profile = $(container).data 'profile'
  model = $(container).data 'model'

  user_is = (role) ->
    profile.roles?.indexOf(role) >= 0

  $.sammy container, ->
    app = @

    model.require 'sotel_portal/partner_signup.js', ->
      if user_is 'sotel_partner_admin'
        app.run '#/inbox'
        return

      app.run '#/partner_signup'
