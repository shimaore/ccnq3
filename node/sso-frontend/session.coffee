
app "session", (server) ->
  express = require('express')
  server.use express.bodyDecoder()
  server.use express.cookieDecoder()
  server.use express.session(secret: config.session_secret)

# GET and DELETE do not require authentication
# They are directly accessed by the client.

get '/session.json': ->
  session.touch()
  send session

get '/session.json/:': ->
  session.touch()
  send session


del '/session.json': ->
  session.destroy (err) ->
    if err?
      send error: err
    else
      send

# Create a new session

put '/session.json': ->
  if @key isnt config.session_keys[request.client.remoteAddress]
    send error: 'Invalid request'

put '/session/value.json': ->
  if @key isnt config.session_keys[request.client.remoteAddress]
    send error: 'Invalid request'
  session.regenerate (err) ->
    session[@field] = @value
    send session
