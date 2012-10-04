do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  ## Number

  number_selector = '#number_record'

  number_tpl = $.compile_template ->
    form id:'number_record', method:'post', action:'#/number', class:'validate', ->

      textbox
        id:'number'
        title:'Number (global number: E.164-without-plus; local number: local_number@number_domain)'
        class:'text'
        value: @number

      textbox
        id:'account'
        title:'Account'
        class:'required text'
        value:@account

      textbox
        id:'inbound_uri'
        title:'Inbound URI (global)'
        class:'uri'
        value:@inbound_uri

      textbox
        id:'outbound_route'
        title:'Outbound Route (global)'
        class:'integer'
        value: @outbound_route

      textbox
        id:'registrant_password'
        title:'Registrant Password (global)'
        class:'text'
        value:@registrant_password

      ###
      # registrant_host actually might be string or array FIXME
      textbox
        id:'registrant_host'
        title:'Registrant Host (global)'
        class:'text'
        value:@registrant_host
      ###

      textbox
        id:'endpoint'
        title:'Endpoint (local)'
        class:'text'
        value:@endpoint

      textbox
        id:'location'
        title:'Location (local)'
        class:'text'
        value:@location

      textbox
        id:'cfa'
        title:'CFA (local)'
        class:'uri'
        value:@cfa

      textbox
        id:'cfb'
        title:'CFB (local)'
        class:'uri'
        value:@cfb

      textbox
        id:'cfda'
        title:'CFDA (local)'
        class:'uri'
        value:@cfda

      textbox
        id:'cfnr'
        title:'CFNR (local)'
        class:'uri'
        value:@cfnr

      textbox
        id:'dialog_timer'
        title:'Maximum Call Duration'
        class:'integer'
        value:@dialog_timer

      textbox
        id:'inv_timer'
        title:'Maximum Ringback Duration'
        class:'integer'
        value:@inv_timer

      checkbox
        id:'privacy'
        title:'Privacy'
        value:@privacy

      textbox
        id:'asserted_number'
        title:'Asserted Number'
        class:'text'
        value:@asserted_number

      checkbox
        id:'reject_anonymous'
        title:'Reject anonymous (inbound)'
        value:@reject_anonymous

      checkbox
        id:'use_blacklist'
        title:'Use blacklist (inbound)'
        value:@use_blacklist

      checkbox
        id:'use_whitelist'
        title:'Use whitelist (inbound)'
        value:@use_whitelist

      textbox
        id:'user_database'
        title:'User Database (voicemail)'
        class:'text'
        value:@user_database

      textbox
        id:'voicemail_sender'
        title:'Notification Sender (voicemail)'
        class:'email'
        value:@voicemail_sender

      input type:'submit'

    form method:'delete', action:'#/number', ->
      input type:'submit', value:'Delete'

    $('form.validate').validate()

  $(document).ready ->

    app = $.sammy container, ->

      number = @createModel 'number'

      number.extend
        beforeSave: (doc) ->

          doc._id = make_id 'number', doc.number

          return doc

      @bind 'error.number', (notice) ->
        console.log "Number error: #{notice.error}"

      @get '#/number', ->
        @swap number_tpl

      @get '#/number/:id', ->
        if not @params.id?
          @swap host_tpl
          return

        @send number.get, @params.id,
          success: (doc) =>
            @swap number_tpl doc
            $(number_selector).data 'doc', doc
          error: =>
            doc = {}
            @swap number_tpl
            $(number_selector).data 'doc', doc

      @bind 'save-number', (event) ->

        doc = $(number_selector).data('doc') ? {}
        $.extend doc, $(number_selector).toDeepJson()

        push = ->
          $.ccnq3.push_document 'provisioning'

        if doc._rev?
          number.update doc._id, doc,
            success: (resp) ->
              number.get resp.id, (doc)->
                $(number_selector).data 'doc', doc
                do push
        else
          number.create doc,
            success: (resp) ->
              number.get resp.id, (doc)->
                $(number_selector).data 'doc', doc
                do push

      @post '#/number', ->
        form_is_valid = $(number_selector).valid()

        if form_is_valid
          @trigger 'save-number'

        return

      @del '#/number', ->

        doc = $(number_selector).data('doc') ? {}

        @send number.remove, doc, ->
          $('#number_form').data 'doc', {}

        return

  Inbox.register 'number',

    list: (doc) ->
      return "Number #{doc.number}"

    form: (doc) ->
      id = encodeURIComponent doc._id
      """
        <p><a href="#/number/#{id}">Edit</a></p>
      """
