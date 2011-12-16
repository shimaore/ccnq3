###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/portal'
  views: {}
  lists: {}
  shows: {}
  filters: {}
  rewrites: []

module.exports = ddoc

ddoc.filters.send_password = p_fun (doc,req) ->
  return doc.send_password? and doc.send_password

ddoc.lists.datatable = p_fun (head,req) ->
  start
    headers:
      'Content-Type': 'application/json'
  fields = req.query.fields.split ' '
  send '{ "aaData": ['
  first_row = true
  while row = getRow()
    do (row) ->
      send ',' if not first_row
      send JSON.stringify (row.value[field] for field in fields)
      first_row = false
  send '] }'

ddoc.views.user_profiles =
  map: p_fun (doc) ->
    if doc.type? and doc.type is 'user' and doc.profile
      emit null, doc.profile

# Attachments (main couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'main'))
