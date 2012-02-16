
do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'
  endpoint_username = (n) -> "endpoint@#{n}"

  container = '#content'

  selector = '#endpoint_record'

  endpoint_tpl = $.compile_template ->
    form id:'endpoint_record', method:'post', action:'#/endpoint', class:'validate', ->

      textbox
        id:'ip'
        title:'IP Address'
        class:'ip'
        value: if not @password then @ip

      textbox
        id:'username'
        title:'Username'
        class:'email'   # in the form username@domain
        value: if @password then @username

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
      $('#endpoint_form').delegate '#ip', 'change', ->
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

          if doc.ip?
            doc.endpoint = doc.ip
          else
            doc.endpoint = doc.username

          delete doc.ip
          delete doc.username
          doc._id = doc.endpoint

          if doc.password?
            [user,domain] = doc.endpoint.split /@/
            challenge = domain
            doc.ha1 = hex_md5 [user,challenge,doc.password].join ':'
            doc.ha1b = hex_md5 [doc.endpoint,challenge,doc.password].join(':')
          else
            delete doc.ha1
            delete doc.ha1b


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
            $('#endpoint_record').data 'doc', doc
          error: =>
            doc = {}
            @swap endpoint_tpl
            $('#endpoint_record').data 'doc', doc

      @bind 'save-endpoint', (event) ->

        doc = $(selector).data('doc') ? {}
        $.extend doc, $(selector).toDeepJson()

        push = ->
          $.ccnq3.push_document 'provisioning'

        if doc.rev?
          endpoint.update doc._id, doc,
            success: (resp) ->
              endpoint.get resp.id, (doc)->
                $(selector).data 'doc', doc
                do push
        else
          model.create doc,
            success: (resp) ->
              model.get resp.id, (doc)->
                $(selector).data 'doc', doc
                do push

      @post '#/endpoint', ->
        form_is_valid = $(selector).valid()

        if form_is_valid
          @trigger 'save-endpoint'

      @del '#/endpoint', ->

        doc = $(selector).data('doc') ? {}

        @send endpoint.remove, doc, ->
          $('#endpoint_form').data 'doc', {}

      Inbox.register 'endpoint',

        list: (doc) ->
          return "Endpoint #{doc.endpoint}"

        form: (doc) ->
          id = encodeURIComponent doc._id
          """
            <p><a href="#/endpoint/#{id}">Edit</a></p>
          """
