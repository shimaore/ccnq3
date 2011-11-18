#!/usr/bin/env coffee
# Copyright (c) 2010  Stephane Alnet
# License: Affero GPL 3+

require('ccnq3_config').get (config)->

  config = config.video_portal

  backends = require './backends'
  sql = ->
    backends.sql            config, arguments...
  dancer_session = ->
    backends.dancer_session config, arguments...
  user_info = ->
    backends.user_info      config, arguments...

  zappa = require 'zappa'
  zappa.run config.port, config.hostname, ->

    @use 'logger'
    , 'bodyParser'
    , 'cookieParser'
    , session:{secret:'a'+Math.random()}
    , 'methodOverride'

    querystring = require 'querystring'
    fs = require 'fs'

    registry_template = ->
      location = 'user.reg.mustache'
      return fs.readFileSync(location, 'utf8')

    crypto = require 'crypto'

    md5_hex = (t) ->
      hash = crypto.createHash('md5')
      hash.update(t)
      return hash.digest('hex')

    # ALTER TABLE realuser ADD agent TEXT;
    # ALTER TABLE realuser ADD user_type TEXT;
    # ALTER TABLE realuser ADD license TEXT;
    # ALTER TABLE realuser ADD account TEXT;
    # ALTER TABLE realuser ADD installation_id TEXT;
    # ALTER TABLE realuser ADD activate_date TEXT;
    # ALTER TABLE realuser ADD original_password TEXT;

    # account parameter might be undefined
    @helper check_user = (account,cb) ->
      dancer_session @cookies, (s) =>
        if s.error? or not s.user_id?
          return cb null, "Session error (#{s.error})"

        user_info s.user_id, (u) =>
          if u.error?
            return cb null, "User access error (#{u.error})"
          return cb(s.account) if u.is_sysadmin
          if account?
            if not u.portal_accounts or u.portal_accounts.indexOf(account) is -1
              return cb null, "You do not have access to this account"
          return cb(s.account)

    @helper check_admin = (cb) ->
      dancer_session @cookies, (s) =>
        if s.error? or not s.user_id?
          return cb "Session error (#{s.error})"

        user_info s.user_id, (u) =>
          if u.error?
            return cb "User access error (#{u.error})"
          return cb() if u.is_sysadmin
          return cb "Not authorized"

    @postrender restrict: ->
      # remove fields that non-admins should not see
      if @not_admin
        $('.admin_only').remove()
      return

    @helper render_d: (log,data) ->
      data.log = log if log?
      @check_admin (not_admin) =>
        data.not_admin = not_admin?
        @render 'default', postrender: 'restrict', data

    @get '/': ->
      @check_user undefined, (account,error) =>
        if error?
          @render 'error', error:error
        else
          @render_d null, @query

    fields = 'username email name address city zip country agent user_type license phone account installation_id activate_date'.split(' ')
    fw_name = config.fw_name # 'ts1.sotelips.net'

    @put '/': ->
      @check_admin (error) =>
        if(error?)
          @render 'error', error:error
        else
          create_user(@body)

    milk = require 'milk'

    @get '/user.reg': ->
      if not @query.user_id?
        return @render 'error', error:'Missing parameter'

      @check_admin (error) =>
        if error?
          return @render 'error', error:error

        sql 'SELECT username, original_password, name FROM realuser WHERE user_id = ?', [@query.user_id], (r) =>
          if r.error?
            return @render 'error', error:r.error

          username = r.rows[0].username
          password = r.rows[0].original_password

          if not password? or password is ''
            return @render 'error', error:'No password, cannot generate'

          password_buffer = new Buffer(password.length+3)
          password_buffer[0] = 4
          password_buffer[1] = password.length+1
          password_buffer.write(password,2)
          password_buffer[password.length+2] = 0
          password_base64 = password_buffer.toString('base64')
          name =  r.rows[0].name

          response.contentType 'application/binary'
          response.send milk.render registry_template(),
            username: username
            name: name
            password_base64: password_base64


    @helper create_user: (data) ->

      sip_name = querystring.escape(data.username)
      sip_id   = [sip_name,fw_name].join('@')

      # Need special handling for password
      if data.password? and data.password != ''
        user_password = md5_hex([data.username,'realtunnel.com',data.password].join(':'))
        sip_password  = md5_hex([sip_name,fw_name,data.password].join(':'))

      values = (params[f] for f in fields)

      if(data.user_id)
        # Update
        setters = (f+'=?' for f in fields)
        if user_password?
          values.push user_password
          setters.push 'password=?'
          values.push data.password
          setters.push 'original_password=?'

        sql 'UPDATE realuser SET '+setters.join(',')+' WHERE user_id = ?', [values..., data.user_id], (r) =>

          if r.error?
            return @render 'error', error:r.error

          sip_setters = ['sipid=?','sipname=?']
          sip_values = [sip_id, sip_name]
          if sip_password?
            sip_values.push sip_password
            sip_setters.push 'password=?'

          sql 'UPDATE sipuser SET '+sip_setters.join(',')+' WHERE user_id = ?', [sip_values...,data.user_id], (r) =>
            if r.error?
              return @render 'error', error:r.error
            @redirect "user.reg?user_id=#{querystring.escape(data.user_id)}"
      else
        # Create
        new_user_id = Math.floor(Math.random()*2000000000)

        if not data.password or not data.username
          return @render 'error', error:'No password or username'

        sql 'INSERT INTO realuser (user_id,password,original_password,'+fields.join(',')+') VALUES (?,?,?,'+('?' for f in fields).join(',')+')', [new_user_id, user_password, data.password, values...], (r) =>
          if r.error?
            return @render 'error', error:r.error
          sql 'INSERT INTO sipuser (sipuser_id,user_id,sipid,sipname,password) VALUES (?,?,?,?,?)', [
            new_user_id,
            new_user_id,
            sip_id,
            sip_name,
            sip_password
          ], (r) =>
            if r.error?
              return @render 'error', error:r.error
            @redirect "user.reg?user_id=#{querystring.escape(new_user_id)}"

    @del '/': ->
      @check_admin (error) =>
        if(error?)
          @render 'error', error:error
        else
          delete_user @query


    @helper delete_user: (data) ->
      if(data.user_id)

        sql 'DELETE FROM realuser WHERE user_id = ?', [data.user_id], (r) =>

          if r.error?
            return @render 'error', error:r.error

          sql 'DELETE FROM sipuser WHERE user_id = ?', [data.user_id], (r) =>
            if r.error?
              return @render 'error', error:r.error
            @render_d 'User account deleted successfully', data


    @client validate: ->
      $(document).ready ->
        $("form.validate").validate()

    # Search by user_id

    @client search: ->
      $(document).ready ->
        $('#username').focus()
        $('#username').autocomplete {
          source: 'search',
          minLength: 2,
        }

        $('#load').click ->
          $.getJSON 'user',{username:$('#username').val()}, (data) ->
            $('#modify').deserialize(data)
            $('#modify input#password').val(undefined).removeClass('required')
            $('#modify input[type="submit"]').val('Modify')
            $('#delete').show().find('input[name="user_id"]').val(data.user_id)
            $('#registry').show().find('input[name="user_id"]').val(data.user_id)

          return false

    @get '/user': ->
      # Return a JSON record for the specified username (must exist)
      sql 'SELECT * FROM realuser WHERE username = ?', [@query.username], (data) ->
        try
          @send data.rows[0]
        catch error
          @send {}

    # send { user_id: '5678', username: @username}

    @get '/search': ->
      rows = []
      # Return a list of usernames matching the @term parameter
      sql 'SELECT username FROM realuser WHERE username LIKE ?', [@query.term+'%'], (data) ->
        try
          @send data.rows.map (a) -> a.username
        catch error
          @send []

    # send ['bob','henry','max']

    # List user_id in account

    @client account: ->
      $(document).ready ->
        $('#account_users_container').hide()

        $('#list_account').submit ->
          $(@).hide()

          $('#account_users_container').show().addClass('ui-widget-content')

          $('#account_users').dataTable {
            bScrollInfinite: true,
            sScrollY: '200px',
            bDestroy: true,
            bProcessing: true,
            bRetrieve: true,
            bJQueryUI: true,
            sAjaxSource: 'account/'+$('#in_account').val()
          }

          return false

    @get '/account/': ->
      @check_admin (error) =>
        if(error?)
          return @send
        sql 'SELECT username FROM realuser', [], (data) ->
          @send { aaData: data.rows.map (a) -> [a.username] }

    @get '/account/:some_account': ->
      @check_user @params.some_account, (account,error) =>
        if(error?)
          return send
        sql 'SELECT username FROM realuser WHERE account = ?', [@params.some_account], (data) ->
          send { aaData: data.rows.map (a) -> [a.username] }

    #  send {
    #    aaData: [
    #      ["bob"],
    #      ["charley"],
    #      ["henry"],
    #    ]
    #  }

    @client ->
      $(document).ready ->
        $('#delete').hide()
        $('#registry').hide()
        $('#modify input[type="submit"]').val('Create')
        $('#content').addClass('ui-widget')
        $('form').addClass('ui-widget-content')
        $('button,input[type="submit"],input[type="reset"]').button()

        $('#license').change ->
          if($(this).val())
            $('#on_license').find('input').addClass('required')
          else
            $('#on_license').find('input').removeClass('required')

        $('#email').change ->
          if not $('#username').val()
            $('#username').val( $('#email').val().replace('@','*') )

        password_charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-".split('')

        random_password = (l) ->
          return '' if l is 0
          return random_password(l-1)+password_charset[Math.floor(Math.random()*password_charset.length)]

        $('#password').val -> random_password(16)
        $('#generate').click ->
          $('#password').val -> random_password(16)
          return false

        $('#modify input[type="reset"]').click ->
          window.location.reload()
          return false


    @view 'error': ->
      @title = 'Error'
      @scripts = [
        '/public/js/default'
      ]
      @stylesheets = [
        '/public/css/default'
      ]

      h1 @title
      div id: 'error', -> 'An errror occurred. Please try again.'
      div id: 'info', -> @error


    @view ->
      @title = 'Portal'
      @scripts = [
        '/public/js/default'
        '/public/js/jquery.deserialize',
        'default',
        'search', 'account', 'validate'
      ]
      @stylesheets = [
        '/public/css/default'
      ]

      lr = (_id,_label,_class) ->
        label "for": _id, -> _label
        input id: _id, name: _id, class: if _class? then _class else 'required'

      l = (_id,_label,_class) ->
        label "for": _id, -> _label
        if _class?
          input id: _id, name: _id, class: _class
        else
          input id: _id, name: _id


      h1 @title

      noscript -> 'Please enable Javascript in your web browser.'

      div id: 'content', =>
        # List all user_id in account
        form id: 'list_account', =>
          label "for": 'in_account', -> 'Account'
          input  id: 'in_account', value: if @account? then @account else ''
          button -> 'Display'

        div id: 'account_users_container', ->
          table id: "account_users", class: 'display', ->
            thead -> tr ->
              th -> 'Username'
            tbody -> ''

        div id: 'error', -> @error
        div id: 'log',   -> @log

        # Modify/Create
        form id: 'modify', class: 'validate admin_only', method: 'post', ->
          input type: 'hidden', name: '_method', value: 'PUT'
          div ->
            lr 'username', 'Username'
            button id: 'load', -> 'Load'
          input type: 'hidden', name: 'user_id'

          div -> lr 'email', 'Email', 'required email'
          div -> lr 'name', 'Name'
          div ->
            lr 'password', 'Password'
            button id: 'generate', -> 'Generate'
          div -> lr 'address', 'Address'
          div -> lr 'zip', 'ZIP'
          div -> lr 'city', 'City'
          div -> lr 'country', 'Country'

          div -> l  'agent', 'Agent'
          div ->
            label "for": 'user_type', -> 'User Type'
            select id: 'user_type', name: 'user_type', class: 'required', ->
              option value: 'demo', -> 'Demo'
              option value: 'paid', -> 'Paid'
          div -> l  'license', 'License'
          div id: "on_license", ->
            div -> l 'phone', 'Phone number'
            div -> l 'account', 'Account number', 'digits'
            div -> l 'installation_id', 'Installation ID'
            div -> l 'activate_date', 'Date of activation', 'date'

          div ->
            input type: 'submit', -> 'Create'

        # New
        form id: 'new', class: 'admin_only', method: 'get', ->
          input type: 'submit', value: 'New'

        # Delete
        form id: 'delete', class: 'admin_only', method: 'post', ->
          input type: 'hidden', name: '_method', value: 'delete'
          input type: 'hidden', name: 'user_id'
          input type: 'submit', value: 'Delete'

        # Registry
        form id: 'registry', class: 'admin_only', method: 'get', action: 'user.reg', ->
          input type: 'hidden', name: 'user_id'
          input type: 'submit', value: 'Download Registry'
