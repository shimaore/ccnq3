###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/inbox'
  views: {}
  lists: {}
  shows: {}
  filters: {}
  rewrites: []

module.exports = ddoc

# Attachments (main couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'usercode'))
