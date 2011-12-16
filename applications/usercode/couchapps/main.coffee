###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/replicate'
  filters: {}

module.exports = ddoc

ddoc.validate_doc_update = p_fun (newDoc, oldDoc, userCtx) ->

  user_is = (role) ->
    userCtx.roles?.indexOf(role) >= 0

  if not user_is('usercode_writer') and not user_is('_admin')
    throw forbidden:'Not authorized to write in this database, roles = #{userCtx.roles?.join(",")}.'

# Filter replication towards the user database.
ddoc.filters.user_pull = p_fun (doc, req) ->

  # Do not replicate this design document.
  if doc._id is '_design/replicate'
    return false

  # Usercode is public and can be freely replicated.
  return true
