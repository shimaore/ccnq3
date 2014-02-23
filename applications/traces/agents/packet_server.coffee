# (c) 2012 Stephane Alnet
#
{exec,spawn} = require('child_process')
fs = require 'fs'
path = require 'path'
zlib = require 'zlib'
byline = require 'byline'
events = require 'events'
pcap_tail = require './pcap_tail'

minutes = 60*1000 # milliseconds

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
  "tcp.srcport"
  "tcp.dstport"
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

tshark_fields = []
for f in trace_field_names
  tshark_fields.push '-e'
  tshark_fields.push f

tshark_line_parser = (t) ->
  return if not t?
  t = t.toString 'utf8' # ascii?
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
#   find_since
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
    fh = "#{options.trace_dir}/.tmp.cap1.#{Math.random()}"

    ## Generate a merged capture file

    # This function tests whether a file is an acceptable input PCAP file.
    is_acceptable = (name,stats) ->
      return no unless name.match /^[a-z].+\.pcap/
      if intf?
        return no unless name[0...intf.length] is intf
      return no unless stats.isFile() and stats.size > 80
      file_time = stats.mtime.getTime()
      if options.find_since?
        return no unless options.find_since < file_time
      yes

    fs.readdir options.trace_dir, (err,files) ->
      if err
        console.error 'readdir(#{options.trace_dir}): #{err}'
        return

      next = (acc,last) ->
        if files.length is 0
          last acc
          return

        name = files.shift()

        full_name = path.join options.trace_dir, name
        fs.stat full_name, (err,stats) ->
          if err
            console.error 'stat(#{full_name}): #{err}'
          else
            if is_acceptable name, stats
              acc.push name:full_name, time:stats.mtime.getTime()
          next acc, last

      next [], (proper_files) ->
        proper_files.sort (a,b) -> a.time - b.time

        # `proper_files` now contains a sorted list of *pcap* files.
        # We build a stash using the last 500 packets matching `ngrep_filter`.
        next_file = (stash,last) ->
          if proper_files.length is 0
            last stash
            return
          file = proper_files.shift()
          input = fs.createReadStream(file.name)
          input = input.pipe zlib.createGunzip() if file.name.match /gz$/
          pcap_tail.tail input, options.ngrep_filter, options.ngrep_limit ? 500, stash, (stash) ->
            next_file stash, last

        next_file [], (stash) ->
          console.log "Going to write #{stash.length} packets to #{fh}."
          pcap_tail.write fs.createWriteStream(fh), stash, run_tshark

    ## Select the proper packets
    if options.pcap?
      tshark_command = [
        'tshark', '-r', fh, '-Y', options.tshark_filter, '-nltad', '-T', 'fields', tshark_fields..., '-P', '-w', options.pcap
      ]
    else
      tshark_command = [
        'tshark', '-r', fh, '-Y', options.tshark_filter, '-nltad', '-T', 'fields', tshark_fields...
      ]

    # stream is tshark.stdout
    tshark_pipe = (stream) ->
      linestream = byline stream
      linestream.on 'data', (line) ->
        data = tshark_line_parser line
        data.intf = intf
        self.emit 'data', data
      linestream.on 'end', ->
        self.end()
      linestream.on 'error', ->
        console.log "Linestream error"
        seld.end()

    # Wait for the pcap_command to terminate.

    run_tshark = ->
      console.log "Staring #{tshark_command}."
      tshark = spawn 'nice', tshark_command,
        stdio: ['ignore','pipe','ignore']

      tshark_kill = ->
        tshark.kill()

      tshark_kill_timer = setTimeout tshark_kill, 10*minutes

      tshark.on 'exit', (code) ->
        console.dir on:'exit', code:code, tshark_command:tshark_command
        clearTimeout tshark_kill_timer
        # Remove the temporary (pcap) file, it's not needed anymore.
        fs.unlink fh, (err) ->
          if err
            console.dir error:err, when: "unlink #{fh}"
        # The response is complete
        self.close()

      tshark_pipe tshark.stdout

  run options.interface

  return self
