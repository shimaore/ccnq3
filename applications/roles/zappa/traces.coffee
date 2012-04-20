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
      @response.writeHead 200,
        'Content-Type': req.headers 'Content-Type'
        'Content-Disposition': req.headers 'Content-Disposition'

      req.on 'error', (e) ->
        console.dir error:e, port:port
        delete servers[port]
      req.on 'end', ->
        console.dir on:'end', port:port
        delete servers[port]
      console.dir start:'pipe', port:port
      # Pipe the body of the PUT request back to the original client.
      req.pipe @response
      return
    servers[port] = server
    server.listen port
    return
