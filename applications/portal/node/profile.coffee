###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

get '/profile.json': ->
  if not session.logged_in?
    return send error:'Not logged in.'

  users_cdb = cdb.new config.profile.users_couchdb_uri
  users_cdb.get "org.couchdb.user:#{session.logged_in}", (r) ->
    if r.error?
      return send r

    send r.profile
