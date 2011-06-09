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

ddoc.filters.user_replication = (doc, req) ->
  # Prefix is required
  if not req.prefix
    return false

  # Only replicate documents, do not replicate _design objects (for example).
  if not doc.account
    return false

  # Replicate documents for which the account is a subset of the prefix.
  if doc.account.substr(0,req.prefix.length) is req.prefix
    return true

  # Do not otherwise replicate
  return false
