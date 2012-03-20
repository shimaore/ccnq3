# (c) 2012 Stephane Alnet
#
http = require 'http'
spawn = require('child_process').spawn
fs = require 'fs'

## Host trace server

## Fields returned in the "JSON" response.
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

fields = ('-e '+f for f in trace_field_names).join ' '

line_parser = (t) ->
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

# The server filters and formats the trace, and starts a one-time
# web server that will output the data.
module.exports = (config,port,doc) ->

  shell = '/bin/sh'

  workdir = config.traces?.workdir ? '/opt/ccnq3/traces' # FIXME default_trace_workdir

  # We _have_ to use a file because tshark cannot read from a pipe/fifo/stdin.
  # (And we need tshark for its filtering and field selection features.)
  fh = "#{workdir}/.tmp.pcap.#{port}"

  ## Generate a merged capture file
  # ngrep is used to pre-filter packets
  ngrep_filter = []
  ngrep_filter.push 'To'+     ':[^\r\n]*' + doc.to_user   if doc.to_user?
  ngrep_filter.push 'From'+   ':[^\r\n]*' + doc.from_user if doc.from_user?
  ngrep_filter.push 'Call-ID'+':[^\r\n]*' + doc.call_id   if doc.call_id?
  ngrep_filter = ngrep_filter.join '|'

  pcap_command = """
    nice find #{workdir} -name '*.pcap' -print0 -o -name '*.pcap.gz' -print0 | \\
    nice xargs -0 mergecap -w - | \\
    nice ngrep -i -l -q -I - -O '#{fh}' '#{ngrep_filter}' >/dev/null
  """

  ## Select the proper packets
  # tshark does the final packet selection
  # In JSON mode it is also used to output the requested fields.
  tshark_filter = []
  if doc.days_ago?
    # Wireshark's format: Nov 12, 1999 08:55:44.123
    d = new Date()
    d.setUTCHours(0); d.setUTCMinutes(0); d.setUTCSeconds(0)
    time = d.getTime() - 86400*doc.days_ago
    today    = new Date(time).toUTCString()
    tomorrow = new Date(time+86400).toUTCString()
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

  switch doc.format
    when 'json'
      tshark_command = """
        nice tshark -r "#{fh}" -R '#{tshark_filter}' -nltad -T fields #{fields}
      """

      # Minimalist web server
      server = http.createServer (req,res) ->
        # We don't care to check the method, URI, etc. Just send the response.
        res.writeHead 200,
          'Content-Type': 'application/json'

        # Start the JSON content.
        # Start the array.
        res.write '['
        first_entry = true

        # Fork the find/mergecap/ngrep pipe.
        pcap = spawn shell

        # Wait for the pcap_command to terminate.
        pcap.on 'exit', ->
          tshark = spawn shell
          tshark.stdin.write tshark_command
          tshark.stdin.end()

          buffer = ''
          process_buffer = ->
            d = buffer.split "\n"
            while d.length > 1
              line = d.shift()
              data = line_parser line
              # Make the array properly formatted
              if not first_entry
                res.write ','
              first_entry = false
              # Write the JSON content
              res.write JSON.stringify(data)
            buffer = d[0]

          tshark.on 'exit', ->
            # Process any leftover content
            do process_buffer
            # Close the JSON content
            # The response is complete
            res.end ']'
            # Remove the temporary (pcap) file
            fs.unlink fh
            # Stop the server (single-shot)
            server.close()

          tshark.stdout.on 'data', (data) ->
            # Accumulate data in the buffer
            buffer += data.toString()
            do process_buffer

        # Start the pcap_command
        pcap.stdin.write pcap_command
        pcap.stdin.end()

      server.listen port

    when 'pcap'
      tshark_command = """
        nice tshark -r "#{fh}" -R '#{tshark_filter}' -w -
      """

      # Minimalist web server
      server = http.createServer (req,res) ->
        # We don't care to check the method, URI, etc. Just send the response.
        res.writeHead 200,
          'Content-Type': 'binary/application'
          'Content-Disposition': 'attachment; filename="trace.pcap"'

        # Fork the find/mergecap/ngrep pipe.
        pcap = spawn shell

        # Wait for the pcap_command to terminate.
        pcap.on 'exit', ->
          tshark = spawn shell
          tshark.stdin.write tshark_command
          tshark.stdin.end()

          tshark.on 'exit', ->
            # Remove the temporary (pcap) file
            fs.unlink fh
            # The response is complete
            res.end()
            # Stop the server (single-shot)
            server.close()

          # Pipe the output of tshark to the client.
          tshark.stdout.pipe(res)

        # Start the pcap_command
        pcap.stdin.write pcap_command
        pcap.stdin.end()

      server.listen port
