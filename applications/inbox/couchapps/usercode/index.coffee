###
Registry of types (so that we can dynamically add types to the inbox).
###

class InboxRegistry

  types: {}

  register: (type,handler) ->
    @types[type] = handler

  registered: (type) ->
    @types[type]?

  """
    List a single document.
  """
  list: (type,doc) -> @types[type]?.list doc

  """
   Generates form content usable to update a single
   document.
  """
  form: (type,doc) -> @types[type]?.form doc

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

# Create a new global Inbox registry
Inbox = window.Inbox = new InboxRegistry()

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
      element = $ default_list_tpl
        type: type
        list: Inbox.list type,doc
        form: Inbox.form type,doc
      element.data 'doc', doc
      return element

  inbox_lists = (docs) ->
    html = ''
    html += inbox_item(doc) for doc in docs
    return html

  $.fn.inbox = (app) ->

    app.swap do inbox_tpl

    inbox_model = app.createModel 'inbox'

    refill = =>
      inbox_model.all
        limit: @.children('.inbox_limit').val() ? defaults.limit
        success: (data) =>
          @.children('.inbox_content').html inbox_lists data.rows

    inbox_model.changes (doc) =>
      @.children('.inbox_content').prepend inbox_item doc
    @.children('.inbox_limit').change ->
      refill()
    refill()


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
