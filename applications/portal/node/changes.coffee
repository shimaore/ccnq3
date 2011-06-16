#!/usr/bin/env coffee
###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

# Proxy a "_changes" CouchDB API for a Socket.IO client.
# The client must provide a full, valid URI (including authentication if needed).

using 'url'
using 'cdb_changes'
using 'querystring'

at connection: ->
  delete client.cdb_client

at disconnection: ->
  delete client.cdb_client

msg changes: ->
  uri = url.parse config.changes.base_couchdb_uri
  delete uri.href
  uri.pathname = message.database
  options =
    uri: url.format uri
    filter_name: message.filter_name
    filter_params: message.filter_params
    since: message.since
    cookie: client.request.headers.cookie
  client.cdb_client = cdb_changes.monitor options, (doc) ->
    send 'changes', database: database, changes: doc
