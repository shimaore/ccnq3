###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/cdr'
  language: 'javascript'
  shows: {}
  filters: {}

module.exports = ddoc

p_fun = (f) -> '('+f+')'

ddoc.filters.not_deleted = p_fun (doc,req) ->
  if doc._deleted?
    not doc._deleted
  else
    true
