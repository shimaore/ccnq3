
do(jQuery,Sammy) ->

  $ = jQuery

  $.fn.disable = () ->
    $(@).attr('disabled','true')

  $.fn.enable = () ->
    $(@).removeAttr('disabled')

  container = 'body'

  $.getScript 'public/js/jquery.validate.js'

  coffeekup_helpers =

    checkbox: (attrs) ->
      attrs.type = 'checkbox'
      attrs.name = attrs.id
      attrs.value ?= 'true'
      attrs.class ?= 'normal'
      label  for:attrs.name, class:attrs.class, ->
        span attrs.title
        input attrs

    textbox: (attrs) ->
      attrs.type = 'text'
      attrs.name = attrs.id
      attrs.class ?= 'normal'
      label  for:attrs.name, class:attrs.class, ->
        span attrs.title
        input attrs

    text_area: (attrs) ->
      attrs.name = attrs.id
      attrs.rows ?= 3
      attrs.cols ?= 3
      attrs.class ?= 'normal'
      label  for:attrs.name, class:attrs.class, ->
        span attrs.title
        textarea attrs

  compile_template = (template) ->
    CoffeeKup.compile template, hardcode: coffeekup_helpers

  endpoint_tpl = compile_template ->
    form id:'endpoint_form', method:'post', action:'#/endpoint', ->
      textbox id:'ip',       title:'IP Address', value:@ip
      textbox id:'username', title:'Username',   value:@username # in the form username@domain
      textbox id:'password', title:'Password',   value:@password

    coffeescript ->
      $('#endpoint_form').delegate '#ip', 'change', ->
        if $(@).val()?
          $('#username').disable()
          $('#password').disable()
        else
          $('#username').enable()
          $('#password').enable()

  main_tpl = compile_template ->
    div id:'main', ->

      a href:'#/endpoint', 'Endpoints'

  ## endpoints = Sammy(container).createModel 'endpoints'
  # endpoints.extend
  #   beforeSave: (doc) -> ...

  $(document).ready ->
    app = $.sammy container, ->

      @use 'Title'
      @use 'Couch', 'endpoints'

      @template_engine = 'coffeekup'

      @setTitle 'Provisioning'

      @get '#/', ->
        @swap main_tpl()
  
      @get '#/endpoint', ->
        if @params.endpoints?
          # Get the data record, then render it and display the result.
          @send endpoints.get "endpoint:#{endpoint}", (data)->
            @swap endpoint_tpl data
        else
          @swap endpoint_tpl()
  
      @post '#/endpoint', ->
        # Do something
        @doc = $('#endpoint_form').toDeepJson()
        @doc.endpoint = if @doc.ip? then @doc.ip else @doc.username then
        @doc._id = "endpoint:#{@doc.endpoint}"

    app.run '#/'
