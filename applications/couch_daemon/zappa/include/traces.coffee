@include = ->

  ccnq3 = require 'ccnq3'
  ccnq3.config (c) -> config = c

  @put '/_ccnq3/traces', ->

    if not @req.user?
      return @failure error:"Not authorized (probably a bug)"

    request = @body

    if not request.format?
      return @failure error:"Request must contain `format` field."
    if not request.reference?
      return @failure error:"Request must contain `reference` field."

    ccnq3.amqp (connection) =>
      if connection?
        connection.exchange 'traces', {type:'topic',durable:true}, (exchange) =>
          exchange.publish 'request', request
          connection.end()
          @success request
      else
        @failure error:"No connection to AMQP server."
    return
