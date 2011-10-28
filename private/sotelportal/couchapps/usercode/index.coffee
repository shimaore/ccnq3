$(document).ready ->

  container = '#content'

  # Only present if within portal (not in pure couchapp)
  profile = $(container).data 'profile'

  default_tpl = $.compile_template ->

    div id:'login_container'
    h3 id:'log'

    # Here goes the main page layout.
    div ->
      div id: 'main', ->
        'You are now successfully logged into the SoTel Systems Online Portal.'

    if @roles.indexOf('partner') < 0
      a href:'#/partner_signup', -> 'Become a SoTel Systems partner!'

  app = $.sammy container, ->

    @get '#/', (app) ->

        @swap default_tpl profile
        $('#log').html "Welcome #{profile.profile.name}."

  model = $(container).data 'model'
  # Retrieve the proper profile before starting the application.
  # (This allows for the profile to be available in other modules.)
  model.viewDocs "portal/user", (docs) =>
    profile = docs[0] ? {}
    $(container).data 'profile', profile

    user_is = (role) ->
      profile.roles?.indexOf(role) >= 0

    if user_is 'sotel_partner_admin'
      app.run '#/partner_admin'
      return

    app.run '#/partner_signup'
