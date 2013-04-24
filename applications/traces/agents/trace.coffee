# (c) 2012 Stephane Alnet
#
fs = require 'fs'
packet_server = require './packet_server'
wireshark_date = require './wireshark_date'

## Host trace server

default_workdir = '/opt/ccnq3/traces'

# The server filters and formats the trace.
module.exports = (config,doc) ->

  console.dir doc: doc

  ## Generate a merged capture file
  # ngrep is used to pre-filter packets
  ngrep_filter = []
  ngrep_filter.push '(To|t)'+     ':[^\r\n]*' + doc.to_user   if doc.to_user?
  ngrep_filter.push '(From|f)'+   ':[^\r\n]*' + doc.from_user if doc.from_user?
  ngrep_filter.push '(Call-ID|i)'+':[^\r\n]*' + doc.call_id   if doc.call_id?
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

  options =
    interface: doc.interface
    trace_dir: config.traces?.workdir ? default_workdir
    # find_filter is left empty
    ngrep_filter: ngrep_filter
    tshark_filter: tshark_filter

  if doc.reference?
    options.pcap = options.trace_dir+'/.tmp.cap2.'+doc.reference

  [ packet_server(options), options.pcap ]
