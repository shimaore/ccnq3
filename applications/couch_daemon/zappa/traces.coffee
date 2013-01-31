@include = ->

  ccnq3 = require 'ccnq3'
  ccnq3.config (c) -> config = c

  @put '/_ccnq3/traces', ->

    if not @req.user?
      return @failure error:"Not authorized (probably a bug)"

    ccnq3.amqp (connection) ->
      if connection?
        options =
          type: 'topic'
          durable: true
          autoDelete: true
        connection.exchange 'traces', options, (exchange) ->
          exchange.publish 'request', @body
          connection.end()
          @success body
      else
        @failure error:"No connection to AMQP server."
    return
