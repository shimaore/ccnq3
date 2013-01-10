# (c) 2012 Stephane Alnet
#
ccnq3 = require 'ccnq3'
json_pipe = require './json_pipe'
trace = require './trace'

module.exports = (config,doc) ->

  self = trace config, doc

  sb = require('stream-buffers')
  res = new sb.WritableStreamBuffer()

  switch doc.format
    when 'json'
      json_pipe self, res
      contentType = 'application/json'
    when 'pcap'
      self.on 'pipe', (stream) ->
        stream.pipe res
      contentType = 'binary/application'

  ccnq3.amqp.exchange 'traces', {type:'topic',durable:true}, (e) ->
    e.publish doc.id, res, {contentType}
