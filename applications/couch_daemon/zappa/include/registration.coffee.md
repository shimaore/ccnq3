    @include = ->

      ccnq3 = require 'ccnq3'
      ccnq3.config (c) -> config = c

      uuid = require 'uuid'

      @get '/_ccnq3/registration/:username', ->

        if not @req.user?
          return @failure error:"Not authorized (probably a bug)"

        reply_to = uuid()

        request = {username,reply_to}

        ccnq3.amqp (c) =>
          if c?
            c.exchange 'registration', {type:'topic',durable:true}, (e) =>

The response is sent back using the specified queue.

              c.queue reply_to, exclusive:true, (q) ->
                q.bind 'response'
                q.subscribe (doc) ->
                  c.end()
                  @success doc

              e.publish 'request', request
          else
            @failure error:"No connection to AMQP server."
        return
