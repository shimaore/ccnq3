###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

# Install:
#   coffee -c replicate.coffee
#   couchapp push replcate.js http://127.0.0.1:5984/db

ddoc =
  _id: '_design/provisioning'
  filters: {}

module.exports = ddoc

ddoc.filters.user_push = (doc, req) ->

  # Do not replicate design documents from the source "provisioning" database.
  if doc._id.match /^_design/
    return false

  # Need a type
  if not doc.type?
    return false

  provisioning_types = ["number","endpoint","location","host","domain"]

  # Only replicate provisioning documents.
  if provisioning_type.indexOf(doc.type) < 0
    return false

  # They must have a valid account.
  if not doc.account
    return false

  # The user context provided to us by the replication agent.
  ctx = JSON.parse req.query.ctx

  # Ensure we only replicate documents the user actually is authorized to update.
  for role in ctx.roles
    do (role) ->
      # Note how this uses the "update" filter.
      prefix = role.match("^update:#{@source}:(.*)$")?[1]
      if prefix?

        # Replicate documents for which the account is a subset of the prefix.
        if doc.account.substr(0,req.prefix.length) is req.prefix
          return true

  # Do not otherwise replicate
  return false


# Attachments (user couchapp)
couchapp = require('couchapp')
path     = require('path')
couchapp.loadAttachments(ddoc, path.join(__dirname, 'usercode'))
