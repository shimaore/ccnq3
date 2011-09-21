###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

ddoc =
  _id: '_design/partner'
  filters: {}

module.exports = ddoc

ddoc.filters.user_push = (doc, req) ->

  # Do not replicate design documents from the source "partner" database.
  if doc._id.match /^_design/
    return false

  # The user context provided to us by the replication agent.
  ctx = JSON.parse req.query.ctx

  # Ensure we only replicate documents the user actually is authorized to update.

  # For partner signup documents, ensure only the user's documents are sent.
  if m = doc._id.match /^partner_signup:(.*)$/
    if m[1] is ctx.name
      return true

  # Do not otherwise replicate
  return false


# Attachments (user couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'usercode'))
