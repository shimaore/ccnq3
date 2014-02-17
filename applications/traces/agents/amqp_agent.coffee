#!/usr/bin/env coffee

ccnq3 = require 'ccnq3'
trace_couch = require './trace_couch'

config = null
ccnq3.config (c) -> config = c

while true
  ccnq3.amqp (c) ->
    c.exchange 'traces', {type:'topic',durable:true,autoDelete:false}, (e) ->
      c.queue "trace-requests-#{config.host}", (q) ->
        q.bind e, 'request'
        q.subscribe (doc) ->
          trace_couch config, doc
