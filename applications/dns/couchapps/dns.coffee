###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/dns'
  language: 'javascript'
  views: {}
  shows: {}
  filters: {}

module.exports = ddoc

p_fun = (f) -> '('+f+')'

ddoc.views.domains =
  map: p_fun (doc) ->
    # Only return documents that will end up as domains that can be served
    if doc.type? and doc.type is 'domain' and doc.records?
      emit null, null

