# require 'form.js'

Inbox.register 'number', class NumberHandler

  list_tpl: $.compile_template ->
    div class:'number', ->
      "Number: #{@number}"

  form_tpl: $.compile_template ->
    textbox
      id:'number'
      title:'Phone Number'
      value: @number
      class:'required phone'
      if @number? then readonly:true

    # Inbound call routing
    textbox
      id:'endpoint'
      title:'Endpoint'
      value:@endpoint
      class:'required endpoint' # Please make me into a http://jqueryui.com/demos/autocomplete !

    # etc.

    # Outbound call routing
    textbox
      id:'outbound_route'
      title:"Outbound Route"
      value:@outbound_route
      class:'route'
    # The outbound route will only be used if the endpoint allows it.

    # etc.

Inbox.register 'endpoint', class EndpointHandler

  list_tpl: $.compile_template ->
    div class:'endpoint', ->
      "Endpoint: #{@endpoint}"

  form_tpl: $.compile_template ->
    # The endpoint ID is either:
    #   - an IP address
    #   - a SIP contact (user@domain)
    textbox
      id:'endpoint'
      title:'Endpoint'
      value:@endpoint
      class:'required endpoint'
      if @endpoint? then readonly:true

    textbox
      id:'password'
      title:'Password'
      value:@password
      class:'password'

    coffeescript ->
      $('#endpoint').change ->
        if $(@).val()?.match /@/
          $('#password').show()
        else
          $('#password').hide()

    hidden id:'ha1', value:@ha1
    hidden id:'ha1b', value:@ha1b

    coffeescript ->
      recompute_ha1 = ->
        challenge = ''
        username = $('#endpoint').val()
        password = $('#password').val()
        ha1  = md5_hex [username,challenge,password].join(':')
        ha1b = md5_hex ["#{username}@#{challenge}",challenge,password].join(':')
        $('#ha1').val ha1
        $('#ha1b').val ha1b

      $('#endpoint').change -> recompute_ha1
      $('#password').change -> recompute_ha1

    textbox
      id:'dialog_timer'
      title:"Maximum call duration"
      value:@dialog_timer
      class:'number'
      hint:"Leave empty for no maximum"

    textbox
      id:'outbound_route'
      title:"Outbound Route"
      value:@outbound_route
      class:'route'
    # If null, the numbers' outbound-routes will be used.
    # Otherwise the endpoint's outbound route overwrites the numbers' outbound
    # routes.
