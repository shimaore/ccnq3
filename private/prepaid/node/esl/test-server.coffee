esl = require "./esl"
util = require 'util'

server = esl.createServer (res) ->
    res.on 'esl_event', (req,res) ->
      util.log "Event"+util.inspect req

    res.send 'connect', (req,res) ->
      @call_data = req.headers
      res.send 'linger', (req,res) ->
        res.send 'event json HEARTBEAT'
server.listen(7000)

