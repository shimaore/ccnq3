###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/provisioning'
  filters: {}

module.exports = ddoc

ddoc.filters.user_push = p_fun (doc, req) ->

  # Do not replicate design documents from the source "provisioning" database.
  if doc._id.match /^_design/
    return false

  # Need a type
  if not doc.type?
    return false

  provisioning_types = ["number","endpoint","location","host","domain"]

  # Only replicate provisioning documents.
  if provisioning_types.indexOf(doc.type) < 0
    return false

  # They must have a valid account.
  if not doc.account?
    return false

  # The user context provided to us by the replication agent.
  ctx = JSON.parse req.query.ctx

  # Ensure we only replicate documents the user actually is authorized to update.
  match_role = (role) ->
    # Note how this uses the "update" filter.
    m = role.match(/^update:provisioning:(.*)$/)
    return false if not m?
    prefix = m[1]
    # Replicate documents for which the account is a subset of the prefix.
    return doc.account.substr(0,prefix.length) is prefix

  return true for role in ctx.roles when match_role role

  # Do not otherwise replicate
  return false


# Attachments (user couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'usercode'))
