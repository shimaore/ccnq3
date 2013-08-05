ccnq3 = require 'ccnq3'
process_changes = require './process-changes'
ccnq3.config (config) ->
  ccnq3.amqp (c) ->
    c.exchange 'commands', {type:'topic',durable:true}, (e) ->
      c.queue "commands-#{config.host}", (q) ->

        # Handle requests specific to this host.
        q.bind e, "request-#{config.host}"
        # Handle requests addressed to all hosts.
        q.bind e, "request"

        q.subscribe (request) ->
          process_changes request, (response) ->
            e.publish "response-#{request.reference}", response
