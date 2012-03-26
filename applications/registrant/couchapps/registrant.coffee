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
    if doc.registrant_password? and doc.registrant_host?
      value =
        number: doc.number
        password: doc.registrant_password
      # registrant_host might be a string or an array of strings
      if typeof doc.registrant_host is 'string'
        emit doc.registrant_host, value
      else
        for host in doc.registrant_host
          emit host, value
