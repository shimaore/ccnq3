# (c) 2012 Stephane Alnet
#
http = require 'http'
spawn = require('child_process').spawn
fs = require 'fs'
packet_server = require './packet_server'
json_pipe = require './json_pipe'

## Host trace server

default_workdir = '/opt/ccnq3/traces'

# The server filters and formats the trace, and starts a one-time
# web server that will output the data.
module.exports = (config,port,doc) ->

  console.dir port:port, doc: doc

  ## Generate a merged capture file
  # ngrep is used to pre-filter packets
  ngrep_filter = []
  ngrep_filter.push 'To'+     ':[^\r\n]*' + doc.to_user   if doc.to_user?
  ngrep_filter.push 'From'+   ':[^\r\n]*' + doc.from_user if doc.from_user?
  ngrep_filter.push 'Call-ID'+':[^\r\n]*' + doc.call_id   if doc.call_id?
  ngrep_filter = ngrep_filter.join '|'

  ## Select the proper packets
  # tshark does the final packet selection
  # In JSON mode it is also used to output the requested fields.
  tshark_filter = []
  if doc.days_ago?
    # Wireshark's format: Nov 12, 1999 08:55:44.123
    #
    #
    one_day = 86400*1000
    d = new Date()
    d.setHours(0); d.setMinutes(0); d.setSeconds(0)
    time = d.getTime() - one_day*doc.days_ago
    today    = wireshark_date new Date time
    tomorrow = wireshark_date new Date time+one_day
    tshark_filter.push """
      frame.time >= "#{today}" && frame.time < "#{tomorrow}"
    """
  tshark_filter.push """
    (sip.r-uri.user contains "#{doc.to_user}" || sip.to.user contains "#{doc.to_user}")
  """ if doc.to_user?
  tshark_filter.push """
    sip.from.user contains "#{doc.from_user}"
  """ if doc.from_user?
  tshark_filter.push """
    sip.Call-ID == "#{doc.call_id}"
  """ if doc.call_id?
  tshark_filter = tshark_filter.join ' && '

  # Minimalist web server
  server = http.createServer (req,res) ->

    console.dir req:req,res:res,port:port

    # We don't care to check the method, URI, etc. Just send the response.
    switch doc.format
      when 'json'
        res.writeHead 200,
          'Content-Type': 'application/json'
      when 'pcap'
        res.writeHead 200,
          'Content-Type': 'binary/application'
          'Content-Disposition': 'attachment; filename="trace.pcap"'

    options =
      format: doc.format
      trace_dir: config.traces?.workdir ? default_workdir
      ngrep_filter: ngrep_filter
      tshark_filter: tshark_filter

    self = packet_server config, options

    switch doc.format
      when 'json'
        json_pipe self, res
      when 'pcap'
        self.on 'pipe', (stream) ->
          stream.pipe res

    self.on 'close', ->
      # Stop the server (single-shot)
      server.close()

  server.on 'error', (e) -> console.dir error:e
  console.dir server:'listen', port:port
  server.listen port
