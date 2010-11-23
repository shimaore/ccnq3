#!/usr/bin/env zappa

include 'server.coffee'

using 'http'

def db_name: 'default'

helper sql: (_sql,_p,cb) ->
  data =
    sql: _sql
    params: _p
  db = http.createClient(6789,'localhost')
  content = JSON.stringify(data)
  request = db.request('POST','/'+db_name,{'Content-Type':'text/json','Content-length': content.length})
  request.write content
  request.end
  request.on 'response', (response) ->
    _data = ''
    response.on 'data', (chunk) -> _data += chunk
    response.on 'end', -> cb(JSON.parse(_data))

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

postrender restrict: ->
  # remove fields that non-admins should not see

helper check_agent: (account) ->
  return # XXX
  if request?
    redirect '/login' unless @user_is_agent or @user_is_admin
  else
    client.disconnect() unless @user_is_agent or @user_is_admin

helper check_admin: ->
  return # XXX
  if request?
    redirect '/login' unless @user_is_admin
  else
    client.disconnect() unless @user_is_admin

get '/': ->
  check_agent
  render 'default', apply: 'restrict'

def fields: 'username name address city zip country agent user_type license phone account installation_id activate_date'.split(' ')
def fw_name: 'ts1.sotelips.net'

using 'querystring'

put '/': ->
  check_admin

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

    sql 'UPDATE realuser SET '+setters.join(',')+' WHERE user_id = ?', [values..., @user_id], (r) ->

      if r.error?
        return render 'error'

      sip_setters = ['sipid=?','sipname=?']
      sip_values = [sip_id, sip_name]
      if sip_password?
        sip_values.push sip_password
        sip_setters.push 'password=?'

      sql 'UPDATE sipuser SET '+sip_setters.join(',')+' WHERE user_id = ?', [sip_values...,@user_id], (r) ->
        if r.error?
          return render 'error'
        @log = 'User account modified successfully'
        render 'default', apply: 'restrict'
  else
    # Create
    new_user_id = Math.floor(Math.random()*2000000000)
    sql 'INSERT INTO realuser (user_id,password,'+fields.join(',')+') VALUES (?,?,'+('?' for f in fields).join(',')+')', [new_user_id, user_password, values...], (r) ->
      if r.error?
        return render 'error'
      sql 'INSERT INTO sipuser (sipuser_id,user_id,sipid,sipname,password) VALUES (?,?,?,?,?)', [
        new_user_id,
        new_user_id,
        sip_id,
        sip_name,
        sip_password
      ], (r) ->
        if r.error?
          return render 'error'
        @log = 'User account created successfully'
        render 'default', apply: 'restrict'


postrender restrict: ->
  # $('.staff').remove() unless @user.role is 'staff'

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
        $('#delete').show()

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
  check_admin(@account)
  rows = []
  sql 'SELECT username FROM realuser', [], (data) ->
    send { aaData: data.rows.map (a) -> [a.username] }

get '/account/:account': ->
  check_agent(@account)
  rows = []
  sql 'SELECT username FROM realuser WHERE account = ?', [@account], (data) ->
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
    $('#modify input[type="submit"]').val('Create')
    $('#content').addClass('ui-widget')
    $('form').addClass('ui-widget-content')
    $('button,input[type="submit"],input[type="reset"]').button()

    $('#license').change ->
      if($(this).val())
        $('#on_license').find('input').addClass('required')
      else
        $('#on_license').find('input').removeClass('required')

view 'error': ->
  @title = 'Error'
  @scripts = [
    '/javascripts/jquery',
    '/javascripts/jquery-ui',
  ]
  @stylesheets = [
    '/stylesheets/style',
    '/stylesheets/jquery-ui',
  ]

  h1 @title
  div id: 'error', -> 'An errror occurred. Please try again.'


view ->
  @title = 'Portal'
  @scripts = [
    '/javascripts/jquery',
    '/javascripts/jquery-ui',
    '/javascripts/jquery.validate',
    '/javascripts/jquery.datatables',
    '/javascripts/jquery.deserialize',
    '/default',
    '/search', '/account', '/validate'
  ]
  @stylesheets = [
    '/stylesheets/style',
    '/stylesheets/jquery-ui',
    '/stylesheets/datatables'
  ]

  lr = (_id,_label) ->
    label for: _id, -> _label
    input id: _id, name: _id, class: 'required'

  l = (_id,_label) ->
    label for: _id, -> _label
    input id: _id, name: _id


  h1 @title


  div id: 'content', ->
    # List all user_id in account
    form id: 'list_account', ->
      label for: 'in_account', -> 'Account'
      input  id: 'in_account'
      button -> 'Display'

    div id: 'account_users_container', ->
      table id: "account_users", class: 'display', ->
        thead -> tr ->
          th -> 'Username (email)'
        tbody -> ''

    div id: 'error', -> @error
    div id: 'log',   -> @log

    # Modify/Create
    form id: 'modify', class: 'validate', method: 'post', ->
      input type: 'hidden', name: '_method', value: 'PUT'
      div ->
        lr 'username', 'Username (email)'
        button id: 'load', -> 'Load'
      input type: 'hidden', name: 'user_id', value: @user_id

      div -> lr 'name', 'Name'
      div -> lr 'password', 'Password'
      div -> lr 'address', 'Address'
      div -> lr 'zip', 'ZIP'
      div -> lr 'city', 'City'
      div -> lr 'country', 'Country'

      div -> l  'agent', 'Agent'
      div ->
        label for: 'user_type', -> 'User Type'
        select id: 'user_type', name: 'user_type', ->
          option value: 'demo', -> 'Demo'
          option value: 'paid', -> 'Paid'
      div -> l  'license', 'License'
      div id: "on_license", ->
        div -> l 'phone', 'Phone number'
        div -> l 'account', 'Account number'
        div -> l 'installation_id', 'Installation ID'
        div -> l 'activate_date', 'Date of activation'

      div ->
        input type: 'submit', -> @user_id? ? 'Modify' : 'Create'
        input type: 'reset', value: "Reset/New"

    # Delete
    form id: 'delete', ->
      input type: 'hidden', name: '_method', value: 'delete'
      input type: 'hidden', name: 'user_id', value: @user_id
      input type: 'submit', value: 'Delete'
