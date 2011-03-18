
net = require('net')
querystring = require('querystring')
util = require('util')

parse_header_text = (header_text) ->
  util.log "parse_header_text #{header_text}"
  header_lines = header_text.split("\n")
  headers = {}
  for line in header_lines
    do (line) ->
      [name,value] = line.split /: /, 1
      headers[name] = value

  # Decode headers: in the case of the "connect" command,
  # the headers are all URI-encoded.
  if headers["Reply-Text"]?.charAt[0] is '%'
    for name, value in headers
      value = querystring.unescape(value)

  util.log "headers = " + util.inspect headers
  return headers

class eslParser
  constructor: (@socket) ->
    util.log "eslParser started"
    @body_left = 0
    @buffer = ""

  capture_body: (data) ->
    util.log "capture_body: #{data}"
    if data.length < @body_left
      @buffer    += data
      @body_left -= data.length
    else
      body = @buffer + data.substring(0,@body_left)
      @buffer = data.substring(@body_left)
      @body_left = 0
      @process @headers, body
      @headers = {}

  capture_headers: (data) ->
    util.log "capture_headers: #{data}"
    header_end = data.indexOf("\n\n")

    if header_end < 0
      @buffer += data
      return

    # Consume the headers
    header_text = @buffer + data.substring(0,header_end)
    @buffer = data.substring(header_end+2)
    # Parse the header lines
    @headers = parse_header_text(header_text)
    # Figure out whether a body is expected
    if @headers["Content-Length"]
      @body_left = @headers["Content-Length"]
    else
      @process @headers
      @headers = {}

  on_data: (data) ->

    # Capture the body as needed
    if @body_left > 0
      return @capture_body data
    else
      return @capture_headers data

  on_end: () ->

  send: (command,args,@command_reply) ->
      util.log "send #{command}" + util.inspect args
      @socket.write "#{command}\n"
      if args?
        for key, value of args
          @socket.write "#{key}: #{value}\n"
      @socket.write "\n"


# This is modelled after Node.js' http.js

connectionListener= (socket) ->
  util.log "connection established"
  socket.setEncoding('ascii')
  parser = new eslParser socket
  socket.on 'data', (data) ->  parser.on_data(data)
  socket.on 'end',  ()     ->  parser.on_end()
  parser.process = (headers,body) ->
    util.log "process: " + util.inspect headers,body
    switch headers['Content-Type']
      when 'auth/request'
        event = 'esl_auth_request'
      when 'command/reply'
        event = 'esl_command_reply'
      when 'text/event-json'
        body = json.parse(body)
        event = 'esl_event'
      when 'text/event-plain'
        body = parse_header_text(body)
        event = 'esl_event'
      when 'log/data'
        event = 'esl_log_data'
      when 'text/disconnect-notice'
        event = 'esl_disconnect_notice'
      else
        event = headers['Content-Type']
    @emit event, headers, body
  @emit 'connect'

class eslServer extends net.Server
  constructor: () ->
    @on 'connection', connectionListener
    super()

exports.createServer = () -> return new eslServer()

class eslClient extends net.Socket
  constructor: (host,port) ->
    @on 'connect', connectionListener
    super port, host

exports.createClient = (host,port) -> return new eslClient(host,port)


# Examples:
###

server = createServer()
server.on 'connect', () ->
    @send 'connect', (headers) ->
      @call_data = headers
      @send 'linger', () ->
        @send 'event json HEARTBEAT'
server.listen(7000)

client =  createClient(host,port)
client.on 'esl_auth_request', () ->
    @send "auth #{auth}", () ->
      @send 'event json HEARTBEAT'

###

