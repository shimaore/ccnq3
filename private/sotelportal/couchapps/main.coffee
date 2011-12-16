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

  if not user_is('sotel_portal_writer') and not user_is('_admin')
    throw forbidden:'Not authorized to write in this database, roles = #{userCtx.roles?.join(",")}.'

# Filter replication towards the user database.
ddoc.filters.user_pull = p_fun (doc, req) ->

  # The user context provided to us by the replication agent.
  ctx = JSON.parse req.query.ctx

  user_is = (role) ->
    ctx.roles?.indexOf(role) >= 0

  # For partner signup documents, ensure only the user's documents are sent.
  if m = doc._id.match /^partner_signup:(.*)$/
    if m[1] is ctx.name
      return true
    # However partner administrators will get copies of all documents.
    if user_is 'sotel_partner_admin'
      return true

  # Do not otherwise replicate
  return false

ddoc.filters.partner_signup = p_fun (doc) ->
  return doc.type is 'partner_signup'
