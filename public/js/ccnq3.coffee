# Javascript Client API for CCNQ3
# (c) 2012 Stephane Alnet

do (jQuery) ->

  $ = jQuery

  $.ccnq3 =

    push_document: (db,cb) ->
      cb ?= ->
        window.location = '#/inbox'
      ee = $.ccnq3.roles.replicate.push db
      ee.on 'success', cb
      ee.on 'error', ->
        alert "Replication failed, please try again."
      return

    portal:

      extra_login: []

      #### `$.ccnq3.portal.profile(callback)`
      # Access the user profile after the user is logged in.
      # The callback receives the profile data as its first and only argument.
      profile: (cb) ->
        $.getJSON '/ccnq3/portal/profile.json', cb

      #### `$.ccnq3.portal.login(username,password)`
      # Log the user in.
      #
      # Events:
      #
      # * `'notify' (text)`
      # * `'success'`
      login: (username,password) ->

        $.ccnq3.portal.extra_login.unshift (auth,next) ->
          auth.notify 'Portal sign in.'
          $.ajax
            type: 'post'
            url: '/ccnq3/portal/login.json'
            data:
              username: username
              password: password
            dataType: 'json'
            success: (data) ->
              if not data.ok
                auth.notify 'Sign in failed.'
                return
              auth.notify ''
              next()
            error: ->
              auth.notify 'Sign in failed.'


        ee = new EventEmitter()

        $.ccnq3.portal.extra_login.push ->
          ee.emit 'success'


        auth =
          username: username
          password: password
          notify: (text) -> ee.emit 'notify', text

        process = (auth,what) ->
          first = what.shift()
          first auth, ->
            process auth, what

        process auth, [$.ccnq3.portal.extra_login...]
        return ee

      #### `$.ccnq3.portal.logout()`
      # Log the user out.
      #
      # Events:
      #
      # * `'success'`
      # * `'error'`
      logout: ->
        ee = new EventEmitter()
        $.getJSON '/ccnq3/portal/logout.json', (data) ->
          if data.ok
            ee.emit 'success'
          else
            ee.emit 'error', data
        return ee

      #### `$.ccnq3.portal.recover(email)`
      # Recover lost password for email address.
      #
      # Events:
      #
      # * `'success'`
      recover: (email) ->
        ee = new EventEmitter()
        $.ajax
          type: 'post'
          url: '/ccnq3/portal/recover.json'
          data:
            email: email
          dataType: 'json'
          success: (data) ->
            if data.ok
              ee.emit 'success'
            else
              ee.emit 'error', data
          error: -> ee.emit 'error'
        return ee

      #### `$.ccnq3.portal.register({email,...})`
      # Register user.
      # At least one field, `email` must be provided.
      #
      # Events:
      #
      # * `'success'`
      # * `'error' (data)`
      register: (data) ->
        ee = new EventEmitter()
        $.ajax
          type: 'PUT'
          url: '/ccnq3/portal/register.json'
          data: data
          dataType: 'json'
          success: (data) ->
            if data.ok
              ee.emit 'success', data
            else
              ee.emit 'error', data
          error: -> ee.emit 'error'
        return ee

    roles:
      replicate:
        #### `$.ccnq3.roles.replicate.pull(db)`
        # Replicate from main database `db` to user database.
        # User must be logged in.
        #
        # Events:
        #
        # * `'success'`
        # * `'error'`
        pull: (db) ->
          ee = new EventEmitter()
          $.ajax
            type: 'post'
            url: "/ccnq3/roles/replicate/pull/#{db}"
            dataType:'json'
            success: (data) ->
              if not data.error?
                ee.emit 'success', data
              else
                ee.emit 'error', data
            error: -> ee.emit 'error'
          return ee

        #### `$.ccnq3.roles.replicate.push(db)`
        # Replicate from user database to main database `db`.
        # User must be logged in.
        #
        # Events:
        #
        # * `'success'`
        # * `'error'`
        push: (db) ->
          ee = new EventEmitter()
          $.ajax
            type: 'post'
            url: "/ccnq3/roles/replicate/push/#{db}"
            dataType:'json'
            success: (data) ->
              if not data.error?
                ee.emit 'success', data
              else
                ee.emit 'error', data
            error: -> ee.emit 'error'
          return ee

      admin:
        #### `$.ccnq3.admin.adduser(name,password)`
        # Create user with given `name` and `password`.
        # Must be logged in with admin rights.
        #
        # Events:
        #
        # * `'success'`
        # * `'error' {error|forbidden}`
        adduser: (name,password) ->
          ee = new EventEmitter()
          $.ajax
            type: 'post'
            url: "/ccnq3/roles/admin/adduser"
            data: {name,password}
            dataType:'json'
            success: (data) ->
              if data.forbidden
                ee.emit 'error', data
                return
              if 200 <= data.status < 300
                ee.emit 'success', data
                return
              ee.emit 'error', data
            error: -> ee.emit 'error'
          return ee

        #### `$.ccnq3.admin.grant(user,operation,source,prefix)`
        # Grant rights to `user` for `operation` (`'update'` or
        # `'access'`) for source (`'endpoint'`, etc.) on given
        # account `prefix`.
        #
        # Events:
        #
        # * `'success'`
        # * `'error'`
        grant: (user,operation,source,prefix) ->
          ee = new EventEmitter()
          $.ajax
            type: 'put'
            url: "/ccnq3/roles/admin/grant/" +
              [user,operation,source,prefix].map(encodeURIComponent).join '/'
            dataType:'json'
            success: (data) ->
              if data.forbidden
                ee.emit 'error', data
                return
              if not data.error?
                ee.emit 'success'
              else
                ee.emit 'error', data
            error: -> ee.emit 'error'
          return ee

        #### `$.ccnq3.admin.revoke(user,operation,source,prefix)`
        # Revoke rights. See `grant` above for arguments description.
        #
        # Events:
        #
        # * `'success'`
        # * `'error'`
        revoke: (user,operation,source,prefix) ->
          ee = new EventEmitter()
          $.ajax
            type: 'del'
            url: "/ccnq3/roles/admin/grant/" +
              [user,operation,source,prefix].map(encodeURIComponent).join '/'
            dataType:'json'
            success: (data) ->
              if data.forbidden
                ee.emit 'error', data
                return
              if not data.error?
                ee.emit 'success'
              else
                ee.emit 'error', data
            error: -> ee.emit 'error'
          return ee

        #### `$.ccnq3.admin.host(user)`
        # Internal use.
        #
        # Events:
        #
        # * `'success'`
        # * `'error'`
        host: (user) ->
          ee = new EventEmitter()
          $.ajax
            type: 'put'
            url: "/ccnq3/roles/admin/grant/#{encodeURIComponent user}/host"
            dataType:'json'
            success: (data) ->
              if data.forbidden
                ee.emit 'error', data
                return
              if data.ok
                ee.emit 'success'
              else
                ee.emit 'error', data.error ? data.forbidden
            error: -> ee.emit 'error'
          return ee

        #### `$.ccnq3.admin.confirm(user)`
        # Internal use.
        #
        # Events:
        #
        # * `'success'`
        # * `'error'`
        confirm: (user) ->
          ee = new EventEmitter()
          $.ajax
            type: 'put'
            url: "/ccnq3/roles/admin/grant/#{encodeURIComponent user}/confirmed"
            dataType:'json'
            success: (data) ->
              if data.forbidden
                ee.emit 'error', data
                return
              if data.ok
                ee.emit 'success'
              else
                ee.emit 'error', data.error ? data.forbidden
            error: -> ee.emit 'error'
          return ee

      #### `$.ccnq3.roles.userdb(name)`
      # Internal use.
      # Create user database `db`.
      # Must be logged in.
      #
      # Events:
      #
      # * `'success'`
      # * `'error'`
      userdb: (db) ->
        ee = new EventEmitter()
        $.ajax
          type: 'put'
          url: "/ccnq3/roles/userdb/#{encodeURIComponent db}"
          dataType:'json'
          cache: false
          success: (data) ->
            if data.ok
              ee.emit 'success'
            else
              ee.emit 'error', data
          error: -> ee.emit 'error'
        return ee
