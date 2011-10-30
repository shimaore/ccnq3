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
    div class:"inbox_item #{@type}", type:@type, ->
      div class:'inbox_item_header', ->
        @list
      div class:'inbox_item_body', ->
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
      # Hide the body at startup
      element.children('.inbox_item_body').hide()
      # Clicking on the header will show/hide the body.
      element.children('.inbox_item_header').click ->
        element.children('.inbox_item_body').toggle()
      # (This is one interaction model. Clicking on the header could e.g. open a dialog.)
      return element

  $.fn.inbox = (app,inbox_model) ->

    app.swap do inbox_tpl

    refill = =>
      inbox_model.viewDocs 'inbox/by_date',
        include_docs: true
        descending: true
        limit: @children('.inbox_limit').val() ? defaults.limit
      , (docs) =>
          content = @find('.inbox_content')
          content.empty()
          for doc in docs
            do (doc) ->
              content.append inbox_item doc

    @data 'changes', inbox_model.changes (results) =>
      content = @find('.inbox_content')
      for r in results
        do (r) ->
          # FIXME Remove potentially existing document from the displayed list.
          return if r.deleted
          content.prepend inbox_item r.doc  if r.doc?

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
