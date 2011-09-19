###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/_users'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

ddoc.filters.user_export = (doc,req) ->

  ctx = JSON.parse req.ctx

  # Normally the test would be along the lines of:
  if not doc.name is ctx.name
    return false

  # However since we do not currently have anything to check changes in the _users
  # database, simply refuse the transfer.
  return false

# Attachments (user couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'usercode'))
