
do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = '#content'

  selector = '#endpoint_record'

  endpoint_tpl = $.compile_template ->
    form id:'endpoint_record', method:'post', action:'#/endpoint', class:'validate', ->

      if not @user_ip
        @username = @endpoint

      textbox
        id:'user_ip'
        title:'Static IP Address'
        class:'ip'
        value: @user_ip

      textbox
        id:'username'
        title:'Username'
        class:'email'   # in the form user@domain
        value: @username

      textbox
        id:'password'
        title:'Password'
        class:'text'
        value:@password

      textbox
        id:'account'
        title:'Account'
        class:'required text'
        value:@account

      textbox
        id:'location'
        title:'Location'
        class:'text'
        value:@location

      textbox
        id:'outbound_route'
        title:'Outbound Route'
        class:'integer'
        value:@outbound_route

      input type:'submit'

    form method:'delete', action:'#/endpoint', ->
      input type:'submit', value:'Delete'

    coffeescript ->
      $('#endpoint_record').delegate '#user_ip', 'change', ->
        if $(@).val()?
          $('#username').disable()
          $('#password').disable()
        else
          $('#username').enable()
          $('#password').enable()

    $('form.validate').validate()

  $(document).ready ->

    app = $.sammy container, ->

      endpoint = @createModel 'endpoint'

      endpoint.extend
        beforeSave: (doc) ->

          if doc.user_ip?
            doc.endpoint = doc.user_ip
          else
            doc.endpoint = doc.username

          delete doc.username
          doc._id = make_id 'endpoint', doc.endpoint

          if doc.password?
            [user,domain] = doc.endpoint.split /@/
            challenge = domain
            doc.ha1 = hex_md5 [user,challenge,doc.password].join ':'
            doc.ha1b = hex_md5 [doc.endpoint,challenge,doc.password].join(':')
          else
            delete doc.ha1
            delete doc.ha1b

          return doc

      @bind 'error.endpoint', (notice) ->
        console.log "Endpoint error: #{notice.error}"

      @get '#/endpoint', ->
        @swap endpoint_tpl

      @get '#/endpoint/:id', ->
        if not @params.id?
          @swap host_tpl
          return

        @send endpoint.get, @params.id,
          success: (doc) =>
            @swap endpoint_tpl doc
            $(selector).data 'doc', doc
          error: =>
            doc = {}
            @swap endpoint_tpl
            $(selector).data 'doc', doc

      @bind 'save-endpoint', (event) ->

        doc = $(selector).data('doc') ? {}
        $.extend doc, $(selector).toDeepJson()

        push = ->
          $.ccnq3.push_document 'provisioning'

        if doc._rev?
          endpoint.update doc._id, doc,
            success: (resp) ->
              endpoint.get resp.id, (doc)->
                $(selector).data 'doc', doc
                do push
        else
          endpoint.create doc,
            success: (resp) ->
              endpoint.get resp.id, (doc)->
                $(selector).data 'doc', doc
                do push

      @post '#/endpoint', ->
        form_is_valid = $(selector).valid()

        if form_is_valid
          @trigger 'save-endpoint'

        return

      @del '#/endpoint', ->

        doc = $(selector).data('doc') ? {}

        @send endpoint.remove, doc, ->
          $('#endpoint_form').data 'doc', {}

        return

      Inbox.register 'endpoint',

        list: (doc) ->
          return "Endpoint #{doc.endpoint}"

        form: (doc) ->
          id = encodeURIComponent doc._id
          """
            <p><a href="#/endpoint/#{id}">Edit</a></p>
          """
