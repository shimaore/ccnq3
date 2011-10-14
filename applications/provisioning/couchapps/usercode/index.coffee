
do(jQuery,Sammy) ->

  $ = jQuery

  make_id = (t,n) -> [t,n].join ':'

  container = 'body'

  endpoint_tpl = $.compile_template ->
    form id:'endpoint_form', method:'post', action:'#/endpoint', ->
      textbox id:'ip',       title:'IP Address', value:@ip
      textbox id:'username', title:'Username',   value:@username # in the form username@domain
      textbox id:'password', title:'Password',   value:@password

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

  main_tpl = $.compile_template ->
    div id:'main', ->

      a href:'#/endpoint', 'Endpoints'

  $(document).ready ->

    app = $.sammy container, ->

      @use 'Title'
      @use 'Couch' #, dbname

      endpoints = @createModel('endpoints')

      # endpoints.extend
      #   beforeSave: (doc) -> ...

      @template_engine = 'coffeekup'

      @setTitle 'Provisioning'

      @bind 'error.endpoints', (notice) ->
        alert "An error occurred: #{notice.error}"

      @get '#/', ->
        @swap main_tpl()

      @get '#/endpoint', ->
        if @params.endpoint?
          # Get the data record, then render it and display the result.
          @send endpoints.get, make_id('endpoint',@params.endpoint), (doc)=>
            $('#endpoint_form').data 'doc', doc
            @swap endpoint_tpl doc
        else
          @swap endpoint_tpl()

      @post '#/endpoint', ->
        # Do something
        doc = $('#endpoint_form').data 'doc'
        doc ?= {}
        former_doc = doc
        $.extend doc, $('#endpoint_form').toDeepJson()

        doc.endpoint = if doc.ip? then doc.ip else doc.username
        doc._id = make_id('endpoint',doc.endpoint)

        if doc._id is former_doc._id
          @send endpoints.update, doc._id, doc, ->
            $('#endpoint_form').data 'doc', doc
        else
          delete doc._rev
          @send endpoints.remove, former_doc, (doc)=>
            @send endpoints.save,  doc, ->
              $('#endpoint_form').data 'doc', doc

      @del '#/endpoint', ->
        former_doc = $('#endpoint_form').data 'doc'
        @send endpoints.remove, former_doc, ->
          $('#endpoint_form').data 'doc', {}

    app.run '#/'
