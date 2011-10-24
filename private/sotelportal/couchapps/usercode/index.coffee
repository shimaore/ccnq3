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
    @template_engine = 'coffeekup'

    # Should use the proper database when used on a local replica, where
    # profile is empty.
    @use 'Couch', profile?.user_database

    model = @createModel 'sotel_portal'

    model.extend
      require: (name,cb) =>
        $.getScript @db.uri + "_design/sotel_portal/#{name}", cb

    $(container).data 'model', model

    @bind 'error.sotel_portal', (notice) ->
      $('#log').append "An error occurred: #{notice.error}"

    $('#log').ajaxError ->
      $(@).append arguments[3]

    @get '#/', (app) ->

        @swap default_tpl profile
        $('#log').html "Welcome #{profile.profile.name}."

        #-# Put back to get the Logout button
        # $.getScript '/u/login.js'

        # Load the applications
        # TODO: replace by an enumeration of the _design documents in the
        #       user database;
        #       each of them offers a "load.js" (or do two-steps with
        #       something à la "package.json").
        #       (This would include dependencies like the "Interaction" list
        #       above.)


  model = $(container).data 'model'
  # Retrieve the proper profile before starting the application.
  # (This allows for the profile to be available in other modules.)
  model.viewDocs "sotel_portal/user", (docs) =>
    profile = docs[0] ? {}
    $(container).data 'profile', profile

    user_is = (role) ->
      profile.roles?.indexOf(role) >= 0

    # Do all "require" before starting the application.
    $.getScript '/_users/_design/portal/user_management.js' # only accessible to some users
    if user_is 'sotel_partner_admin'
      model.require 'partner_management.js', ->
        app.run '#/partner_admin'
      return

    model.require 'partner_signup.js', ->
      # app.run '#/'
      app.run '#/partner_signup'
