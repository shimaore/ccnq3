#
# OBSOLETE
#
http = require 'http'
json_pipe = require './json_pipe'
trace = require './trace'

## Host trace server

# The server filters and formats the trace, and starts a one-time
# web server that will output the data.
module.exports = (config,port,doc) ->

  console.dir port:port, doc: doc

  # Minimalist web server
  server = http.createServer (req,res) ->

    console.dir req:req,res:res,port:port

    # We don't care to check the method, URI, etc. Just send the response.
    switch doc.format
      when 'json'
        res.writeHead 200,
          'Content-Type': 'application/json'
      when 'pcap'
        res.writeHead 200,
          'Content-Type': 'binary/application'
          'Content-Disposition': 'attachment; filename="trace.pcap"'

    self = trace config, doc

    switch doc.format
      when 'json'
        json_pipe self, res
      when 'pcap'
        self.on 'pipe', (stream) ->
          stream.pipe res

    self.on 'close', ->
      # Stop the server (single-shot)
      server.close()

  server.on 'error', (e) -> console.dir error:e
  console.dir server:'listen', port:port
  server.listen port
