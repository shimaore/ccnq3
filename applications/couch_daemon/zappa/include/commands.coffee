@include = ->

  ccnq3 = require 'ccnq3'
  ccnq3.config (c) -> config = c

  @put '/_ccnq3/commands', ->

    if not @req.user?
      return @failure error:"Not authorized (probably a bug)"

    request = @body
    request.reference ?= 'x'+Math.random()

    ccnq3.amqp (connection) =>
      if connection?
        connection.exchange 'commands', {type:'topic',durable:true}, (exchange) =>
          # Be ready to receive the response(s) -- but only pick the first one.
          connection.queue "couch_daemon-#{config.host}-#{request.reference}", (queue) ->
            queue.bind exchange, "response-#{request.reference}"
            queue.subscribe (response) ->
              connection.end()
              @success response
          # Send the request to one host specifically.
          if request.host?
            exchange.publish "request-#{request.host}", request
          # Send the request to all hosts.
          else
            exchange.publish "request", request
      else
        @failure error:"No connection to AMQP server."
    return
