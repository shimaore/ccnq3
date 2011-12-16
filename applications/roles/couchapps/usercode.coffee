###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/_users'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

ddoc.filters.user_push = p_fun (doc,req) ->

  # Do not replicate design documents from the _users database.
  if doc._id.match /^_design/
    return false

  # If there is no name field do not bother further.
  if not doc.name?
    return false

  ctx = JSON.parse req.query.ctx

  # Normally the test would be along the lines of:
  if not doc.name is ctx.name
    return false

  # However since we do not currently have anything to check changes in the _users
  # database, simply refuse the transfer.
  return false
