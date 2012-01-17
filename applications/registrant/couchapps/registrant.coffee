###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/registrant'
  language: 'javascript'
  views: {}
  filters: {}

module.exports = ddoc

p_fun = (f) -> '('+f+')'

ddoc.views.registrant =
  map: p_fun (doc) ->
    if doc.registrant_password?
      emit doc.number, doc.registrant_password
