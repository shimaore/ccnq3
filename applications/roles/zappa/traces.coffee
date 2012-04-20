@include = ->
  # traces_proxy
  # A proxy to access opened traces servers.
  http = require 'http'

  servers = {}

  @get '/roles/traces/:host/:port', ->

    unless @session.roles?.indexOf 'access:traces:' >= 0
      return @send error:'Unauthorized'

    port = @request.param 'port'

    original_response = @response

    server = http.createServer (req,res) ->
      original_response.writeHead 200
      # 'Content-Type': req.headers 'Content-Type'
      # 'Content-Disposition': req.headers 'Content-Disposition'

      req.on 'error', (e) ->
        console.dir error:e, port:port
        delete servers[port]
        server.close()
      req.on 'end', ->
        console.dir on:'end', port:port
        delete servers[port]
        server.close()

      # Pipe the body of the PUT request back to the original client.
      console.dir start:'pipe', port:port
      req.pipe original_response
      res.end()
      return
    servers[port] = server
    server.listen port
    return
