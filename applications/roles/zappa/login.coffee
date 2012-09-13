@include = ->

  @coffee '/ccnq3/roles/login.js': ->

    extra_login = $.ccnq3.portal.extra_login

    # Directives in this file are in reverse order so that we can stack them
    # at the beginning of extra_login.

    # Replicate the user's record
    extra_login.unshift (auth,next) ->
      auth.notify 'Replicating the user record.'

      ee = $.ccnq3.roles.replicate.pull '_users'
      ee.on 'success', ->
        auth.notify ''
        next()
      ee.on 'error', ->
        auth.notify 'User replication startup failed.'
        return

    # Replicate the usercode applications
    extra_login.unshift (auth,next) ->
      auth.notify 'Replicating the applications.'
      ee = $.ccnq3.roles.replicate.pull 'usercode'
      ee.on 'success', ->
        auth.notify ''
        next()
      ee.on 'error', ->
        auth.notify 'Applications replication startup failed.'
        return

    # Get the user profile and create/access the user db.
    extra_login.unshift (auth,next) ->
      auth.notify 'Validating your profile.'
      $.ccnq3.portal.profile (profile) ->
        if profile.error?
          auth.notify 'Could not access your profile.'
          return
        auth.notify "Welcome #{profile.name}."
        $.ajax
          url: profile.userdb_base_uri+'/'+profile.user_database
          dataType: 'json'
          cache: false
          success: ->
            # Database already exists.
            next()
          error: ->
            # Attempt to create the database.
            auth.notify "Welcome #{profile.name} (creating your database)."
            ee = $.ccnq3.userdb profile.user_database
            ee.on 'success', ->
              auth.notify "Welcome #{profile.name} (database created)."
              next()
            ee.on 'error', ->
              auth.notify 'Could not create your database.'
              return

    # Log into CouchDB so that we can access the user's database directly.
    extra_login.unshift (auth,next) ->

      options =
        type: 'post'
        url: '/_session'
        username: auth.username
        password: auth.password
        data:
          name:     auth.username
          password: auth.password
        dataType: 'json' # should set the Accept header
        cache: false
        success: ->
          auth.notify ''
          next()
        error: ->
          auth.notify 'Database sign-in failed.'

      auth.notify 'Signing you into the database.'
      $.ajax options
