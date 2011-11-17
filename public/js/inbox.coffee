###
Registry of types (so that we can dynamically add types to the inbox).
###

class InboxRegistry

  types: {}

  """
    register adds a set of handler functions to the registry.
    The following handlers may be provided:
      form
      list
  """
  register: (type,priority,handler) ->
    if typeof priority is 'object'
      # No priority provided, assume " default",
      # and the priority argument is actually the handler.
      handler = priority
      priority = ' default' # The space should make it first in the list.
    console.log "Registering type #{type} at priority #{priority}"
    @types[type] ?= []
    @types[type][priority] = handler

  registered: (type) ->
    @types[type]?

  sorted_keys: (type) ->
    (k for k of @types[type]).sort()

  """
    The list function must provide a short text which is displayed
    in the inbox as the short text ('subject') for the item.

    All 'list' methods registered for the type are used in their
    (lexicographical) priority order, although generally you'll want
    to only offer one such function.
  """
  list: (type,doc) -> (@types[t].list? doc for t in @sorted_keys(type)).join ''

  """
    The 'form' function may provide any content that is displayed
    when the specific item is opened.
    This includes form content usable to update a single
    document.

    All 'form' methods registered for the type are used in their
    (lexicographical) priority order.
  """
  form: (type,doc) -> (@types[t].form? doc for t in @sorted_keys(type)).join ''

# Create a new global Inbox registry
@Inbox = window.Inbox = new InboxRegistry()
