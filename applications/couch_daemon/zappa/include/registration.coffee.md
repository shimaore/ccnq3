    @include = ->

      ccnq3 = require 'ccnq3'
      ccnq3.config (c) -> config = c

      uuid = require 'uuid'

      @get '/_ccnq3/registration/:username', ->

        if not @req.user?
          return @failure error:"Not authorized (probably a bug)"

        username = @params.username
        reply_to = uuid()

        request = {username}

        ccnq3.amqp (c) =>
          if c?
            c.exchange 'registration', {type:'topic',durable:true}, (e) =>

The response is sent back using the specified queue

              c.queue reply_to, exclusive:true, (q) ->

which is bound to a topic with the same name.

                q.bind e, reply_to
                q.subscribe (doc) ->
                  c.end()
                  @success doc

The request is sent using topic `request`. The queue on the server is bound to that topic.

              e.publish 'request', request, replyTo:reply_to
          else
            @failure error:"No connection to AMQP server."
        return
