p_fun = (f) -> '('+f+')'

ddoc = {
    _id: '_design/voicemail-store'
  , views: {}
  , filters: {} # used by _changes
}

module.exports = ddoc

ddoc.filters.numbers = p_fun (doc,req) ->
  return doc.type is 'number' and doc.user_database?
