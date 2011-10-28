###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/portal'
  views: {}
  filters: {}

module.exports = ddoc

ddoc.views.user =
  map: (doc) ->
    if doc.type is 'user'
      emit null, null

# Attachments (user couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'portal'))
