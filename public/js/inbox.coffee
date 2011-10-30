###
Registry of types (so that we can dynamically add types to the inbox).
###

class InboxRegistry

  types: {}

  register: (type,handler) ->
    console.log "Registering type #{type}"
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
@InboxHandler = window.InboxHandler = InboxHandler
@Inbox = window.Inbox = new InboxRegistry()
