###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/inbox'
  views: {}
  lists: {}
  shows: {}
  filters: {}
  rewrites: []

module.exports = ddoc

ddoc.views.by_date =
  map: p_fun (doc) ->
    if doc.type? and doc.updated_at?
      emit doc.updated_at, null

ddoc.views.by_type =
  map: p_fun (doc) ->
    if doc.type?
      emit doc._id, null

# Attachments (main couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'usercode'))
