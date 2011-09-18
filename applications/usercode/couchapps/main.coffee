###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

# Install:
#   coffee -c replicate.coffee
#   couchapp push replcate.js http://127.0.0.1:5984/db

ddoc =
  _id: '_design/replicate'
  filters: {}

module.exports = ddoc

ddoc.validate_doc_update = (newDoc, oldDoc, userCtx) ->

  user_is = (role) ->
    userCtx.roles?.indexOf(role) >= 0

  if not user_is('usercode_writer') and not user_is('_admin')
    throw forbidden:'Not authorized to write in this database, roles = #{userCtx.roles?.join(",")}.'

# Filter replication towards the user database.
ddoc.filters.user_pull = (doc, req) ->

  # Usercode is public and can be freely replicated.
  return true
