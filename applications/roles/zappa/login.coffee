@include = ->

  coffee '/login.js': ->

    extra_login = $.extra_login

    $.extra_login = (next) ->

      # Log into CouchDB so that we can access the user's database directly.
      couchdb_login = (next) ->
        couchdb_options =
          type: 'post'
          url: '/_session'
          username: $('#login_username').val()
          password: $('#login_password').val()
          data:
            name: $('#login_username').val()
            password: $('#login_password').val()
          dataType:'json'
          success: (data) ->
            if not data.ok
              $('#login_error').html('Database sign-in failed.')
              return
            next()

        $('#login_error').html('Signing you into the database.')
        $.ajax(couchdb_options)

      if extra_login?
        extra_login -> couchdb_login (next)
      else
        couchdb_login (next)
