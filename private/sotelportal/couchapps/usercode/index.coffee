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
      a id:'to_partner_signup', href:'#/partner_signup', -> 'Become a SoTel Systems partner!'

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
        $('#to_partner_signup').submit()

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

    # Do all "require" before starting the application.
    model.require 'partner_signup.js', ->
      app.run '#/'
