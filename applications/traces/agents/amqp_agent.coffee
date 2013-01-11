#!/usr/bin/env coffee

ccnq3 = require 'ccnq3'

ccnq3.amqp (c) ->
  c.exchange 'traces', {type:'topic',durable:true}, (e) ->
    c.queue 'trace-requests', (q) ->
      q.bind e, 'request'
      q.subscribe (doc) ->
        switch doc.respond_via ? 'couch'
          when 'amqp'
            require('./trace_amqp') config, doc
          when 'http'
            require('./trace_server') config, doc.port, doc
          when 'couch'
            require('./trace_couch') config, doc
