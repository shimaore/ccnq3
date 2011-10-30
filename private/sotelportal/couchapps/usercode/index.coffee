$(document).ready ->

  container = '#content'

  model = $(container).data 'model'
  # Retrieve the proper profile before starting the application.
  # (This allows for the profile to be available in other modules.)
  model.viewDocs "portal/user", (docs) =>
    profile = docs[0] ? {}
    $(container).data 'profile', profile

    user_is = (role) ->
      profile.roles?.indexOf(role) >= 0

    if user_is 'sotel_partner_admin'
      # model.require 'sotel_portal/partner_admin.js', ->
      #   app.run '#/partner_admin'
      return

    model.require 'sotel_portal/partner_signup.js', ->
      app.run '#/partner_signup'
