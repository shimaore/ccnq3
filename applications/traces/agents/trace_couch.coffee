# Concept: the response is stored either as:
#
# * a CouchDB record with the original request as main doc + JSON content as `packets`
# * a CouchDB record with the original request as main doc + PCAP content as attachment `packets.pcap`
#
# This allows for storage of large responses (a potential issue with AMQP).

ccnq3 = require 'ccnq3'
pico = require 'pico'
json_gather = require './json_gather'
trace = require './trace'
qs = require 'querystring'

module.exports = (config,doc) ->

  return unless doc.reference?

  dest = pico doc.upload_uri ? config.traces.upload_uri
  self = trace config, doc

  doc.type = 'trace'
  doc.host = config.host
  doc._id = ccnq3.make_id doc.type, doc.reference, doc.host

  switch doc.format
    when 'json'
      json_gather self, (packets) ->
        doc.packets = packets
        dest.put doc
    when 'pcap'
      dest.put doc, (e,r,b) ->
        if b?.rev?
          self.on 'pipe', (stream) ->
            stream.pipe dest.request.put "#{qs.escape doc._id}/packets.pcap?rev=#{b.rev}"
