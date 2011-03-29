esl = require "./esl"
util = require 'util'

Unique_ID = 'Unique-ID'

server = esl.createServer (res) ->
    res.on 'esl_event', (req,res) ->
      util.log "Event"+util.inspect req

    res.on 'esl_disconnect_notice', (req,res) ->
      switch req.headers['Content-Disposition']
        when 'linger'      then res.exit()
        when 'disconnect'  then res.end()

    util.log 'connect'
    res.connect (req,res) ->
      @channel_data = req.body
      util.log 'linger'
      res.linger (req,res) ->
        util.log 'event_json'
        res.filter Unique_ID, @channel_data[Unique_ID], (req,res) ->
          res.event_json 'CHANNEL_ANSWER', (req,res) ->
            # variable_target is present because of "set" ... "target=..." in the XML dialplan
            util.log 'bridge'
            res.execute 'bridge', @channel_data.variable_target, (req,res) ->
              util.log "bridge says: "+util.inspect req

server.listen(7000)

