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

      if extra_login?
        couchdb_login auth, -> extra_login auth, next
      else
        couchdb_login auth, next
