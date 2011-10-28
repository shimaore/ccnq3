###
Registry of types (so that we can dynamically add types to the inbox).
###

class Inbox

  types: {}

  register: (type,handler) ->
    @types[type] = handler

  """
    List a single document.
  """
  list: (type,doc) -> @types[type].list doc

  """
   Generates form content usable to update a single
   document.
  """
  form: (type,doc) -> @types[type].form doc

###
Base class for all type handlers.

Typical usage:

  Inbox.register 'foo', class FooHandler extends InboxHandler
    # implements "list" and "form"

(Arguably this base class doesn't currently server any practical purpose.)
###

class InboxHandler

  ###
    Generates HTML code for the specified type.
  ###
  list: (doc) ->
    if @list_tpl? then @list_tpl(doc) else '<span>Missing function</span>'
  form: (doc) ->
    if @form_tpl? then @form_tpl(doc) else '<span>Missing function</span>'

###

  $(dom).inbox(Sammy-app)
    Creates an inbox inside the DOM element using the provided Sammy app.

  $(dom).inbox('refill')
    Updates the inbox content. (The DOM element must previously
    have been made into an inbox using inbox().)

###

do (jQuery) ->
  defaults =
    limit: 10

  $ = jQuery

  inbox_tpl = $.compile_template ->
    div class:'inbox', ->
      div class:'inbox_header', ->
        select class:'inbox_limit', ->
          option value:10, -> 10
          option value:25, -> 25
          option value:50, -> 50
      div class:'inbox_content'

    coffeescript ->
      $('.inbox_limit').change ->
        $('.inbox').inbox('refill')

  default_list_tpl = $.compile_template ->
    div class:'inbox_item', type:@type, ->
      @list
      div class:'inbox_item_form', ->
        @form

  inbox_item = (doc) ->
    default_list_tpl
      type: doc.type
      list: Inbox.list doc.type,doc
      form: Inbox.form doc.type,doc

  Inbox.lists = (docs) ->
    html = ''
    html += inbox_item(doc) for doc in docs
    return html

  $.fn.inbox = (name) ->

    if typeof name isnt 'string'
      app = name
      inbox_model = app.createModel 'inbox'
      @.data 'inbox_app', app
      @.data 'inbox_model', inbox_model
    else
      app = @.data 'inbox_app'
      inbox_model = @.data 'inbox_model'

    refill = =>
      inbox_model.all
        limit: @.children('.inbox_limit').val() ? defaults.limit
        success: (data) =>
          @.children('.inbox_content').html Inbox.lists data.rows

    switch name
      when 'refill' then refill()

      else
        app.swap do inbox_tpl
        refill()
        inbox_model.changes (doc) =>
          $(@).children('.inbox_content').prepend Inbox.list doc


###
  Sammy code to start the inbox.
###

do (jQuery) ->
  $ = jQuery
  container = '#content'
  profile = $(container).data 'profile'

  $(document).ready ->
    $.sammy container, ->

      @get '#/inbox', =>
        $(container).inbox(@)
