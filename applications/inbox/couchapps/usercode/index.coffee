do (jQuery) ->
  defaults =
    limit: 10

  $ = jQuery

  inbox_tpl = $.compile_template ->
    div class:'inbox', ->
      div class:'inbox_header', ->
        span 'Show '
        select class:'inbox_limit', ->
          option value:10, -> '10'
          option value:25, -> '25'
          option value:50, -> '50'
      div class:'inbox_content'


  default_list_tpl = $.compile_template ->
    div class:'inbox_item', type:@type, ->
      @list
      div class:'inbox_item_form', ->
        @form

  inbox_item = (doc) ->
    type = doc.type
    if type? and Inbox.registered(type)
      try
        element = $ default_list_tpl
          type: type
          list: Inbox.list type,doc
          form: Inbox.form type,doc
      catch error
        console.log "Rendering #{type} failed: #{error}"
      element.data 'doc', doc
      console.log element
      return element

  $.fn.inbox_items = (docs) ->
    (@append inbox_item(doc)) for doc in docs
    return @

  $.fn.inbox = (app,inbox_model) ->

    app.swap do inbox_tpl

    refill = =>
      inbox_model.viewDocs 'inbox/by_date',
        include_docs: true
        descending: true
        limit: @children('.inbox_limit').val() ? defaults.limit
      , (docs) =>
          @children('.inbox_content')
          .empty()
          .inbox_items docs

    inbox_model.changes (doc) =>
      @children('.inbox_content').prepend inbox_item doc

    @children('.inbox_limit').change ->
      refill()

    refill()
    return @


###
  Sammy code to start the inbox.
###

do (jQuery) ->
  $ = jQuery
  container = '#content'
  profile = $(container).data 'profile'

  $(document).ready ->
    $.sammy container, ->

      inbox_model = @createModel 'inbox'

      @get '#/inbox', =>
        $(container).inbox(@,inbox_model)
