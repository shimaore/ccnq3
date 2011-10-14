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

    if @roles.indexOf('partner') >= 0
      a href:'#/partner_signup', -> 'Become a SoTel Systems partner!'

  app = $.sammy container, ->
    @template_engine = 'coffeekup'

    # Should use the proper database when used on a local replica, where
    # profile is empty.
    @use 'Couch', profile?.user_database

    model = @createModel 'sotel_portal'

    model.extend
      require: (name,cb) ->
        $.getScript model.db.uri + "_design/sotel_portal/#{name}", cb

    $(container).data 'model', model

    @bind 'error.sotel_portal', (notice) ->
      alert "An error occurred: #{notice.error}"

    @get '#/', ->

      @send model.viewDocs, "sotel_portal/user", (docs) =>
        profile = docs[0] ? {}
        $(container).data 'profile', profile
        @swap default_tpl profile

        #-# Put back to get the Logout button
        # $.getScript '/u/login.js'

        $('#log').html "Welcome #{profile.profile.name}."
        # Load the applications
        # TODO: replace by an enumeration of the _design documents in the
        #       user database;
        #       each of them offers a "load.js" (or do two-steps with
        #       something à la "package.json").
        #       (This would include dependencies like the "Interaction" list
        #       above.)
        @send model.require, 'partner_signup.js', =>
          @runRoute 'get', '#/partner_signup'

  app.run '#/'
