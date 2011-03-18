esl = require "./esl"

server = esl.createServer()
server.on 'start', () ->
    @send 'connect', (headers) ->
      @call_data = headers
      @send 'linger', () ->
        @send 'event json HEARTBEAT'
server.listen(7000)

