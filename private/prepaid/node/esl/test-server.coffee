esl = require "./esl"
util = require 'util'

server = esl.createServer (res) ->
    res.on 'esl_event', (req,res) ->
      util.log "Event"+util.inspect req

    res.on 'esl_disconnect_notice', (req,res) ->
      switch req.headers['Content-Disposition']
        when 'linger'      then res.send 'exit'
        when 'disconnect'  then res.end()

    res.send 'connect', (req,res) ->
      @channel_data = req.body
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

