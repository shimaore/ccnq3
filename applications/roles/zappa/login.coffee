@include = ->

  @coffee '/roles/login.js': ->

    extra_login = $.extra_login

    $.extra_login = (auth,next) ->

      # Log into CouchDB so that we can access the user's database directly.
      couchdb_login = (auth,next) ->
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
        auth.$.ajax options

      profile_login = (auth,next) ->
        auth.notify 'Validating your profile.'
        auth.$.getJSON '/u/profile.json', (profile) ->
          if profile.error?
            auth.notify 'Could not access your profile.'
            return
          auth.notify "Welcome #{profile.name}."
          auth.$.ajax
            url: auth.profile.userdb_base_uri+'/'+auth.profile.user_database
            dataType: 'json'
            cache: false
            success: ->
              # Database already exists.
              next()
            error: ->
              # Attempt to create the database.
              auth.notify "Welcome #{profile.name} (creating your database)."
              auth.$.getJSON '/u/user-database.json', (r) ->
                if r.ok
                  auth.notify "Welcome #{profile.name} (database created)."
                  next()
                else
                  auth.notify 'Could not create your database.'
                  return

      # Replicate the usercode applications
      usercode_replicate = (auth,next) ->
        auth.notify 'Replicating the applications.'

        options =
          type: 'post'
          url: '/roles/replicate/pull/usercode'
          dataType:'json'
          success: (data) ->
            if not data.ok
              auth.notify 'Applications replication startup failed.'
              return
            auth.notify ''
            next()

        auth.$.ajax(options)

      # Replicate the user's record
      user_replicate = (auth,next) ->
        auth.notify 'Replicating the user record.'

        options =
          type: 'post'
          url: '/roles/replicate/pull/_users'
          dataType:'json'
          success: (data) ->
            if not data.ok
              auth.notify 'User replication startup failed.'
              return
            auth.notify ''
            next()

        auth.$.ajax(options)

      if extra_login?
        couchdb_login auth, -> profile_login auth, -> create_database auth, -> usercode_replicate auth, -> user_replicate auth, -> extra_login auth, next
      else
        couchdb_login auth, -> profile_login auth, -> create_database auth, -> usercode_replicate auth, -> user_replicate auth, next
