@include = ->
  # traces_proxy
  # A proxy to access opened traces servers.
  http = require 'http'

  servers = {}

  @get '/roles/traces/:host/:port', ->

    unless @session.roles?.indexOf 'access:traces:' >= 0
      return @send error:'Unauthorized'

    port = @request.param 'port'

    server = http.createServer (req,res) =>
      req.pipe @response
      req.on 'error', (e) ->
        console.dir e
        server.close()
        delete servers[port]
      req.on 'end', ->
        server.close()
        delete servers[port]
    server.listen port
    servers[port] = server
    return
