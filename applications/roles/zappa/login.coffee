@include = ->

  coffee '/roles/login.js': ->

    extra_login = $.extra_login

    $.extra_login = (auth,next) ->

      # Log into CouchDB so that we can access the user's database directly.
      couchdb_login = (auth,next) ->
        couchdb_options =
          type: 'get'
          url: '/_session'
          username: auth.username
          password: auth.password
          # data:
          #   name: $('#login_username').val()
          #   password: $('#login_password').val()
          dataType:'json'
          success: (data) ->
            if not data.ok
              auth.notify 'Database sign-in failed.'
              return
            auth.notify ''
            next()

        auth.notify 'Signing you into the database.'
        auth.$.ajax(couchdb_options)

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
        couchdb_login auth, -> usercode_replicate auth, -> user_replicate auth, -> extra_login auth, next
      else
        couchdb_login auth, -> usercode_replicate auth, -> user_replicate auth, next
