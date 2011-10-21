###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/portal'
  views: {}
  lists: {}
  shows: {}
  filters: {}
  rewrites: []

module.exports = ddoc

ddoc.filters.send_password = (doc,req) ->
  return doc.send_password? and doc.send_password

ddoc.lists.datatable = (head,req) ->
  start
    headers:
      'Content-Type': 'application/json'
  fields = req.params.fields.split ' '
  send '{ "aaData": ['
  while row = getRow()
    send row.value[field] for field in fields
    send ','
  send '] }'

ddoc.views.user_profiles =
  map: (doc) ->
    if doc.type? and doc.type is 'user'
      emit null, doc.profile
