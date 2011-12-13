###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/replicate'
  views: {}
  lists: {}     # http://guide.couchdb.org/draft/transforming.html
  shows: {}     # http://guide.couchdb.org/draft/show.html
  filters: {}   # used by _changes
  rewrites: {}  # http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls

module.exports = ddoc

# Used by track_users.
ddoc.filters.confirmed = (doc,req) ->
  user_is = (role) ->
    doc.roles?.indexOf(role) >= 0

  return user_is 'confirmed'

# Document validation.
ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->

  user_was = (role) ->
    oldDoc?.roles?.indexOf(role) >= 0

  if newDoc._deleted
    return

  if not user_was 'confirmed'
    for role in newDoc.roles
      do (role) ->
        if role.match /^(access|update):/
          throw forbidden:"Only confirmed users might be granted account access."

  return

# Used by the replicating agent.
ddoc.filters.user_pull = (doc,req) ->

  ctx = JSON.parse req.query.ctx

  # Only allow the user's own document to be replicated.
  if doc.name is ctx.name
    return true

  return false
