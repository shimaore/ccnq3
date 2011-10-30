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

# Create a new global Inbox registry
@Inbox = window.Inbox = new InboxRegistry()
