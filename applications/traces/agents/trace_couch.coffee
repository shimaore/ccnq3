# Concept: the response is stored as a CouchDB record
# with the original request as main doc
# plus the JSON content as `packets`
# plus the PCAP content as attachment `packets.pcap`
#
# This allows for storage of large responses (a potential issue with AMQP).
# Also this allows to directly access the raw PCAP output without sending
# the request a second time.

ccnq3 = require 'ccnq3'
pico = require 'pico'
json_gather = require './json_gather'
trace = require './trace'
qs = require 'querystring'
fs = require 'fs'

module.exports = (config,doc) ->

  return unless doc.reference?

  dest = pico doc.upload_uri ? config.traces.upload_uri
  [self,pcap] = trace config, doc

  doc.type = 'trace'
  doc.host = config.host
  doc._id = [doc.type, doc.reference, doc.host].join ':'

  json_gather self, (packets) ->
    doc.packets = packets
    dest.put doc, (e,r,b) ->
      if e?
        console.log e
        return
      if b?.rev?
        uri = "#{qs.escape doc._id}/packets.pcap?rev=#{b.rev}"
        options =
          headers:
            'Content-Type': 'application/vnd.tcpdump.pcap'
        fs.createReadStream(pcap).pipe dest.request.put uri, (e,r,b) ->
          fs.unlink pcap, (err) ->
            console.dir error:err, when: "unlink #{pcap}"
