

get '/session.json': ->
  if not @username? and not @password?
    return send {error:'Missing parameters'}

  db = portal_cdb
  db.get @username, (p) =>
    if p.error? or p.password isnt @password
      return send {error:'Invalid password'}
    session.logged_in = @username
    send 'success', 'ok'
