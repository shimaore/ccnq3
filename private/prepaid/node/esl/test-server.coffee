esl = require "./esl"
util = require 'util'

server = esl.createServer (res) ->
    res.on 'esl_event', (req,res) ->
      util.log "Event"+util.inspect req

    res.send 'connect', (req,res) ->
      @channel_data = req.headers
      res.send 'linger', (req,res) ->
        res.send 'event json HEARTBEAT', (req,res) ->
          options =
            'call-command': 'execute'
            'execute-app-name': 'bridge'
            'execute-app-arg': @channel_data.variable_target
            # variable_target is present because of "set" ... "target=..." in the XML dialplan
          # In outbound mode, UUID is not required
          res.send 'sendmsg', options
server.listen(7000)

