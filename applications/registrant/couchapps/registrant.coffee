###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/registrant'
  language: 'javascript'
  views: {}
  lists: {}
  shows: {}
  filters: {}
  updates: {}
  rewrites: []
  lib: {}

module.exports = ddoc

## Registrant view and list

ddoc.views.auth =
  map: p_fun (doc) ->

    if doc.type? and doc.type is 'number' and doc.registrant_password? and doc.registrant_realm?
      emit null, """
        modparam("uac_auth","credential","00#{doc.number}:#{doc.registrant_realm}:#{doc.registrant_password}")\n
      """

    return
