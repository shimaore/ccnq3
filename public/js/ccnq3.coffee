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

      ##
      # $.ccnq3.portal.profile(callback)
      # Access the user profile after the user is logged in.
      # The callback receives the profile data as its first and only argument.
      profile: (cb) ->
        $.getJSON '/ccnq3/portal/profile.json', cb

      ##
      # $.ccnq3.portal.login(username,password)
      # Log the user in.
      # Events:
      #   'notify' (text)
      #   'success'
      login: (username,password,notify) ->

        # Log into the main portal
        main_login = (auth,next) ->
          auth.notify 'Portal sign in.'
          auth.$.ajax
            type: 'post'
            url: '/ccnq3/portal/login.json'
            data:
              username: auth.username
              password: auth.password
            dataType: 'json'
            success: (data) ->
              if not data.ok
                auth.notify 'Sign in failed.'
                return
              auth.notify ''
              next()

        ee = new EventEmitter()

        auth =
          username: username
          password: password
          notify: (text) -> ee.emit 'notify', text
          '$': $

        login_done = ->
          ee.emit 'end'
          ee = null

        if $.extra_login
          main_login auth, -> $.extra_login auth, login_done
        else
          main_login auth, login_done
        return

      ##
      # $.ccnq3.portal.logout()
      # Log the user out.
      # Events:
      #   'success'
      #   'error'
      logout: ->
        ee = new EventEmitter()
        $.ajax
          url: '/ccnq3/portal/logout.json'
          success: (data) ->
            if data.ok
              ee.emit 'success'
            else
              ee.emit 'error', data
          error: -> ee.emit 'error'

      ##
      # $.ccnq3.portal.recover(email)
      # Events:
      #   'success'
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

      ##
      # $.ccnq3.portal.register({name,email,phone})
      # Events:
      #   'success'
      #   'error' (data)
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

    roles:
      replicate:
        ##
        # $.ccnq3.roles.replicate.pull(db)
        # Events:
        #   'success'
        #   'error'
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

        ##
        # $.ccnq3.roles.replicate.push(db)
        # Events:
        #   'success'
        #   'error'
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

      admin:
        ##
        # $.ccnq3.admin.adduser(db)
        # Events:
        #   'success'
        #   'error' {error|forbidden}
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

        ##
        # $.ccnq3.admin.grant(user,operation,source,prefix)
        # Events:
        #   'success'
        #   'error'
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

        ##
        # $.ccnq3.admin.revoke(user,operation,source,prefix)
        # Events:
        #   'success'
        #   'error'
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

        ##
        # $.ccnq3.admin.host(user)
        # Events:
        #   'success'
        #   'error'
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

        ##
        # $.ccnq3.admin.confirm(user)
        # Events:
        #   'success'
        #   'error'
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

      ##
      # $.ccnq3.userdb(name)
      # Events:
      #   'success'
      #   'error'
      userdb: (name) ->
        ee = new EventEmitter()
        $.ajax
          type: 'put'
          url: "/ccnq3/roles/userdb/#{encodeURIComponent user}"
          dataType:'json'
          success: (data) ->
            if data.ok
              ee.emit 'success'
            else
              ee.emit 'error', data
          error: -> ee.emit 'error'
