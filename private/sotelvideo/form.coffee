#!/usr/bin/env zappa
# Copyright (c) 2010  Stephane Alnet
# License: Affero GPL 3+

app "default", (server) ->
  express = require('express')
  server.use express.staticProvider("#{process.cwd()}/public")
  server.use express.favicon()
  server.use express.logger()
  server.use express.bodyDecoder()
  server.use express.cookieDecoder()
  server.use express.session(secret: Math.random())
  server.use express.methodOverride()

using 'querystring'
using 'fs'

helper config: ->
  location = 'form.config'
  return JSON.parse(fs.readFileSync(location, 'utf8'))

helper registry_template: ->
  location = 'user.reg.mustache'
  return fs.readFileSync(location, 'utf8')

include 'backends.coffee'

crypto = require 'crypto'

def md5_hex: (t) ->
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
helper check_user: (account,cb) ->
  dancer_session (s) =>
    if s.error? or not s.user_id?
      return cb "Session error (#{s.error})"
    @account = s.account

    user_info s.user_id, (u) =>
      if u.error?
        return cb "User access error (#{u.error})"
      return cb() if u.is_sysadmin
      if account?
        if not u.portal_accounts or u.portal_accounts.indexOf(account) is -1
          return cb "You do not have access to this account"
      return cb()

helper check_admin: (cb) ->
  dancer_session (s) =>
    if s.error? or not s.user_id?
      return cb "Session error (#{s.error})"

    user_info s.user_id, (u) =>
      if u.error?
        return cb "User access error (#{u.error})"
      return cb() if u.is_sysadmin
      return cb "Not authorized"

postrender restrict: ->
  # remove fields that non-admins should not see
  if @not_admin
    $('.admin_only').remove()
  return

helper render_d: (log) ->
  @log = log if log?
  check_admin (not_admin) =>
    @not_admin = not_admin?
    render 'default', apply: 'restrict'

get '/': ->
  check_user undefined, (error) =>
    if error?
      @error = error
      render 'error'
    else
      render_d()

def fields: 'username email name address city zip country agent user_type license phone account installation_id activate_date'.split(' ')
def fw_name: 'ts1.sotelips.net'

put '/': ->
  check_admin (error) =>
    if(error?)
      @error = error
      render 'error'
    else
      create_user()

using 'milk'

get '/user.reg': ->
  if not @user_id?
    @error = 'Missing parameter'
    return render 'error'

  check_admin (error) =>
    if error?
      @error = error
      return render 'error'

    sql 'SELECT username, original_password, name FROM realuser WHERE user_id = ?', [@user_id], (r) =>
      if r.error?
        @error = r.error
        return render 'error'

      @username = r.rows[0].username
      password  = r.rows[0].original_password
      password_buffer = new Buffer(password.length+3)
      password_buffer[0] = 4
      password_buffer[1] = password.length+1
      password_buffer.write(password,2)
      password_buffer[password.length+2] = 0
      @password_base64 = password_buffer.toString('base64')
      @name =  r.rows[0].name

      response.contentType 'application/binary'
      response.send milk.render(registry_template(),@)


helper create_user: ->

  sip_name = querystring.escape(@username)
  sip_id   = [sip_name,fw_name].join('@')

  # Need special handling for password
  if @password? and @password != ''
    user_password = md5_hex([@username,'realtunnel.com',@password].join(':'))
    sip_password  = md5_hex([sip_name,fw_name,@password].join(':'))

  values = (params[f] for f in fields)

  if(@user_id)
    # Update
    setters = (f+'=?' for f in fields)
    if user_password?
      values.push user_password
      setters.push 'password=?'
      values.push @password
      setters.push 'original_password=?'

    sql 'UPDATE realuser SET '+setters.join(',')+' WHERE user_id = ?', [values..., @user_id], (r) =>

      if r.error?
        @error = r.error
        return render 'error'

      sip_setters = ['sipid=?','sipname=?']
      sip_values = [sip_id, sip_name]
      if sip_password?
        sip_values.push sip_password
        sip_setters.push 'password=?'

      sql 'UPDATE sipuser SET '+sip_setters.join(',')+' WHERE user_id = ?', [sip_values...,@user_id], (r) =>
        if r.error?
          @error = r.error
          return render 'error'
        redirect "user.reg?user_id=#{querystring.escape(@user_id)}"
  else
    # Create
    new_user_id = Math.floor(Math.random()*2000000000)

    if not @password or not @username
      @error = 'Not password or username'
      return render 'error'

    sql 'INSERT INTO realuser (user_id,password,original_password,'+fields.join(',')+') VALUES (?,?,?,'+('?' for f in fields).join(',')+')', [new_user_id, user_password, @password, values...], (r) =>
      if r.error?
        @error = r.error
        return render 'error'
      sql 'INSERT INTO sipuser (sipuser_id,user_id,sipid,sipname,password) VALUES (?,?,?,?,?)', [
        new_user_id,
        new_user_id,
        sip_id,
        sip_name,
        sip_password
      ], (r) =>
        if r.error?
          @error = r.error
          return render 'error'
        redirect "user.reg?user_id=#{querystring.escape(new_user_id)}"

del '/': ->
  check_admin (error) =>
    if(error?)
      @error = error
      render 'error'
    else
      delete_user()


helper delete_user: ->
  if(@user_id)

    sql 'DELETE FROM realuser WHERE user_id = ?', [@user_id], (r) =>

      if r.error?
        @error = r.error
        return render 'error'

      sql 'DELETE FROM sipuser WHERE user_id = ?', [@user_id], (r) =>
        if r.error?
          @error = r.error
          return render 'error'
        render_d 'User account deleted successfully'


client validate: ->
  $(document).ready ->
    $("form.validate").validate();

# Search by user_id

client search: ->
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

get '/user': ->
  # Return a JSON record for the specified username (must exist)
  sql 'SELECT * FROM realuser WHERE username = ?', [@username], (data) ->
    try
      send data.rows[0]
    catch error
      send {}

# send { user_id: '5678', username: @username}

get '/search': ->
  rows = []
  # Return a list of usernames matching the @term parameter
  sql 'SELECT username FROM realuser WHERE username LIKE ?', [@term+'%'], (data) ->
    try
      send data.rows.map (a) -> a.username
    catch error
      send []

# send ['bob','henry','max']

# List user_id in account

client account: ->
  $(document).ready ->
    $('#account_users_container').hide()

    $('#list_account').submit ->
      $(this).hide()

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

get '/account/': ->
  check_admin (error) =>
    if(error?)
      return send
    sql 'SELECT username FROM realuser', [], (data) ->
      send { aaData: data.rows.map (a) -> [a.username] }

get '/account/:some_account': ->
  check_user @some_account, (error) =>
    if(error?)
      return send
    sql 'SELECT username FROM realuser WHERE account = ?', [@some_account], (data) ->
      send { aaData: data.rows.map (a) -> [a.username] }

#  send {
#    aaData: [
#      ["bob"],
#      ["charley"],
#      ["henry"],
#    ]
#  }

client ->
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


view 'error': ->
  @title = 'Error'
  @scripts = [
    'javascripts/jquery',
    'javascripts/jquery-ui',
  ]
  @stylesheets = [
    'stylesheets/style',
    'stylesheets/jquery-ui',
  ]

  h1 @title
  div id: 'error', -> 'An errror occurred. Please try again.'
  div id: 'info', -> @error


view ->
  @title = 'Portal'
  @scripts = [
    'javascripts/jquery',
    'javascripts/jquery-ui',
    'javascripts/jquery.validate',
    'javascripts/jquery.datatables',
    'javascripts/jquery.deserialize',
    'default',
    'search', 'account', 'validate'
  ]
  @stylesheets = [
    'stylesheets/style',
    'stylesheets/jquery-ui',
    'stylesheets/datatables'
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
        input type: 'reset', value: 'New'

    # Delete
    form id: 'delete', class: 'admin_only', method: 'post', ->
      input type: 'hidden', name: '_method', value: 'delete'
      input type: 'hidden', name: 'user_id'
      input type: 'submit', value: 'Delete'

    # Registry
    form id: 'registry', class: 'admin_only', method: 'get', action: 'user.reg', ->
      input type: 'hidden', name: 'user_id'
      input type: 'submit', value: 'Download Registry'
