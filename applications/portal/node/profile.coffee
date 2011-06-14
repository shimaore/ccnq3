###
(c) 2010 Stephane Alnet
Released under the GPL3 license
###

# Load CouchDB
cdb = require 'cdb'

def users_cdb: cdb.new profile.users_couchdb_uri

get '/profile.json': ->
  if not session.logged_in?
    return send error:'Not logged in.'

  users_cdb.get "org.couchdb.user:#{session.logged_in}", (r) ->
    if r.error?
      return send r

    send r.profile
