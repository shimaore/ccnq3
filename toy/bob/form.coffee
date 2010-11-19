#!/usr/bin/env zappa



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

put '/': ->
  check_admin
  render 'default', apply: 'restrict'

postrender restrict: ->
  # $('.staff').remove() unless @user.role is 'staff'

client validate: ->
  $(document).ready ->
    $("form.validate").validate();

# Search by user_id

client search: ->
  $(document).ready ->
    $('#user_id').focus()
    $('#user_id').autocomplete {
      source: 'search',
      minLength: 2,
    }

    $('#load').click ->
      $.getJSON 'user',{user_id:$('#user_id').val()}, (data) ->
        $('#modify').deserialize(data)
        $('#modify input[type="submit"]').val('Modify')
        $('#delete').show()

      return false

get '/user': ->
  send { user_id: @user_id, name: 'bob' }

get '/search': ->
  send [ @term+'mini', @term+'mani', @term+'moe' ]

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

get '/account/:account': ->
  check_agent(@account)
  send {
    aaData: [
      ["bob"],
      ["charley"],
      ["henry"],
      ["all content"]
      ["bob"],
      ["charley"],
      ["henry"],
      ["bob"],
      ["charley"],
      ["henry"],
      ["bob"],
      ["charley"],
      ["henry"],
      ["bob"],
      ["charley"],
      ["henry"],
      ["bob"],
      ["charley"],
      ["henry"],
      ["bob"],
      ["charley"],
      ["henry"],
      ["bob"],
      ["charley"],
      ["henry"],
    ]
  }

client ->
  $(document).ready ->
    $('#delete').hide()
    $('#modify input[type="submit"]').val('Create')
    $('#content').addClass('ui-widget')
    $('form').addClass('ui-widget-content')
    $('button').button()
    $('#on_license').find('input').attr('disabled',true)

    $('#license').change ->
      if($(this).val())
        $('#on_license').find('input').attr('disabled',false)
      else
        $('#on_license').find('input').attr('disabled',true)


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
    input id: _id, class: 'required'

  l = (_id,_label) ->
    label for: _id, -> _label
    input id: _id


  h1 @title
  div id: 'log'


  div id: 'content', ->
    # List all user_id in account
    form id: 'list_account', ->
      label for: 'in_account', -> 'Account'
      input  id: 'in_account'
      button -> 'Display'

    div id: 'account_users_container', ->
      table id: "account_users", class: 'display', ->
        thead -> tr ->
          th -> 'User ID (email)'
        tbody -> ''

    # Modify/Create
    form id: 'modify', class: 'validate', ->
      input type: 'hidden', name: '_method', value: 'put'
      div ->
        lr 'user_id', 'User ID (email)'
        button id: 'load', -> 'Load'
      div -> lr 'name', 'Name'
      div -> lr 'password', 'Password'
      div -> lr 'address', 'Address'
      div -> l  'agent', 'Agent'
      div ->
        label for: 'user_type', -> 'User Type'
        select id: 'user_type', ->
          option value: 'demo', -> 'Demo'
          option value: 'paid', -> 'Paid'
      div -> l  'license', 'License'
      div id: "on_license", ->
        div -> l 'phone', 'Phone number'
        div -> l 'account', 'Account number'
        div -> l 'installation_id', 'Installation ID'
        div -> l 'activation_date', 'Date of activation'


      div ->
        input type: 'submit', -> @user_id? ? 'Modify' : 'Create'
        input type: 'reset', value: "Reset/New"

    # Delete
    form id: 'delete', ->
      input type: 'hidden', name: '_method', value: 'delete'
      input type: 'hidden', name: 'user_id', value: @user_id
      input type: 'submit', value: 'Delete'
