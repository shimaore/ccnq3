$(document).ready ->

  container = '#content'

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

    @get '#/', ->

      $.getJSON "_view/user", (view) =>
        profile = view.rows[0].value ? {}
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
        $.getScript 'partner_signup.js', =>
          @runRoute 'get', '#/partner_signup'

  app.run '#/'
