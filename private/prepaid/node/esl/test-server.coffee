esl = require "./esl"
util = require 'util'

server = esl.createServer (res) ->
    res.on 'esl_event', (req,res) ->
      util.log "Event"+util.inspect req

    res.on 'esl_disconnect_notice', (req,res) ->
      switch req.headers['Content-Disposition']
        when 'linger'      then res.exit()
        when 'disconnect'  then res.end()

    res.connect (req,res) ->
      @channel_data = req.body
      res.linger (req,res) ->
        res.event_json 'HEARTBEAT', (req,res) ->
          # variable_target is present because of "set" ... "target=..." in the XML dialplan
          res.execute 'bridge', @channel_data.variable_target

server.listen(7000)

