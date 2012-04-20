@include = ->
  # traces_proxy
  # A proxy to access opened traces servers.
  http = require 'http'

  @get '/roles/traces/:host/:port', ->

    unless @session.roles?.indexOf 'access:traces:' >= 0
      return @send error:'Unauthorized'

    server = http.CreateServer (req,res) =>
      req.pipe @response
      req.on 'error', ->
        server.close()
      req.on 'end', ->
        server.close()
    server.listen port
    return
