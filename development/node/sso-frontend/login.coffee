put '/login.json': ->
  if not @username? and not @password?
    return send {error:'Missing parameters'}

  # Phase 1: validate username/password


  # Phase 2: create a new session object
  session.regenerate (err) ->
    session.user_id = @user_id
    send session
