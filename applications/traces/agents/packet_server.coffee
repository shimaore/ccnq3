# (c) 2012 Stephane Alnet
#
exec = require('child_process').exec
fs = require 'fs'
byline = require 'byline'
events = require 'events'

## Fields returned in the "JSON" response.
# An additional field "intf" indicates on which interface
# the packet was captured.
trace_field_names = [
  "frame.time"
  "ip.version"
  "ip.dsfield.dscp"
  "ip.src"
  "ip.dst"
  "ip.proto"
  "udp.srcport"
  "udp.dstport"
  "sip.Call-ID"
  "sip.Request-Line"
  "sip.Method"
  "sip.r-uri.user"
  "sip.r-uri.host"
  "sip.r-uri.port"
  "sip.Status-Line"
  "sip.Status-Code"
  "sip.to.user"
  "sip.from.user"
  "sip.From"
  "sip.To"
  "sip.contact.addr"
  "sip.User-Agent"
]

tshark_fields = ('-e '+f for f in trace_field_names).join ' '

tshark_line_parser = (t) ->
  return if not t?
  t.trimRight()
  values = t.split /\t/
  result = {}
  for value, i in values
    do (value,i) ->
      return unless value? and value isnt ''
      value.replace /\\"/g, '"' # tshark escapes " into \"
      result[trace_field_names[i]] = value
  return result

# Options are:
#   interface
#   trace_dir
#   find_filter
#   ngrep_filter
#   tshark_filter
#   pcap          if provided, a PCAP filename
#
# Returned object is an EventEmitter;
# it will trigger three event types:
#   .on 'data', (data) ->
#   .on 'end', () ->
#   .on 'close', () ->

module.exports = (options) ->

  self = new events.EventEmitter

  self.end = ->
    was = self._ended
    self._ended = true
    if not was
      self.emit 'end'
    return

  self.close = ->
    self.end()
    was = self._closed
    self._closed = true
    if not was
      self.emit 'close'
    return

  self.pipe = (s) ->
    if self._ended or self._closed
      console.error 'pipe: self already ended or closed'
    if self._pipe
      console.error 'pipe: self already piped'
    self._pipe = s
    self.emit 'pipe', s
    return

  run = (intf) ->

    # We _have_ to use a file because tshark cannot read from a pipe/fifo/stdin.
    # (And we need tshark for its filtering and field selection features.)
    fh = "#{options.trace_dir}/.tmp.pcap.#{Math.random()}"

    ## Generate a merged capture file
    pcap_command = """
      nice find '#{options.trace_dir}' -maxdepth 1 -type f -size +80c \\
        -name '#{intf ? ''}*.pcap*' #{options.find_filter ? ''} -print0 |  \\
      nice xargs -0 -r mergecap -w - | \\
      nice ngrep -i -l -q -I - -O '#{fh}' '#{options.ngrep_filter}' >/dev/null
    """

    ## Select the proper packets
    if options.pcap?
      tshark_command = """
        nice tshark -r "#{fh}" -R '#{options.tshark_filter}' -nltad -T fields #{tshark_fields} -P -w "#{options.pcap}"
      """
    else
      tshark_command = """
        nice tshark -r "#{fh}" -R '#{options.tshark_filter}' -nltad -T fields #{tshark_fields}
      """

    # stream is tshark.stdout
    tshark_pipe = (stream) ->
      linestream = byline stream
      linestream.on 'data', (line) ->
        data = tshark_line_parser line
        data.intf = intf
        self.emit 'data', data
      linestream.on 'end', ->
        self.end()

    # Fork the find/mergecap/ngrep pipe.
    pcap = exec pcap_command,
      stdio: ['ignore','ignore','ignore']

    # Wait for the pcap_command to terminate.
    pcap.on 'exit', (code) ->
      if code isnt 0
        console.dir on:'exit', code:code, pcap_command:pcap_command
        # Remove the temporary (pcap) file
        fs.unlink fh
        # The response is complete
        self.close()
        return

      tshark = exec tshark_command,
        stdio: ['ignore','pipe','ignore']

      tshark.on 'exit', (code) ->
        console.dir on:'exit', code:code, tshark_command:tshark_command
        # Remove the temporary (pcap) file, it's not needed anymore.
        fs.unlink fh
        # The response is complete
        self.close()

      tshark_pipe tshark.stdout

  run options.interface

  return self
