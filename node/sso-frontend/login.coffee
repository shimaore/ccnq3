put '/login.json': ->
  if not @username? and not @password?
    return send {error:'Missing parameters'}

  options =
    method: 'PUT'
    headers:
      cookies:


  json_req.request options, (data) ->
    if data.error?
      send error: data.error
      return
    if data.user_id?
      send success: 'ok'
    else
      send error: 'failed'


