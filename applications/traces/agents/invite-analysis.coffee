# Analyze PCAP captures (up to one hour) and generate one-per-line JSON records
# specifying the response codes to INVITE queries.
# Note: re-INVITEs are treated the same as initial INVITEs.
# Note: the timestamps may be outside the one-hour window. Filter unwanted records.

# The callback is called once for each entry, with a record containing four strings:
#   timestamp: "yyyy/mm/dd hh:mm"
#   src: "ip:port" (the host emitting the response)
#   dst: "ip:port" (the host that emitted the INVITE)
#   code: "nnn" (the 3-digits response code; only final (200 and above) response codes)

exec = require('child_process').exec
byline = require 'byline'

fields = 'timestamp src dst code'.split /\s+/

default_workdir = '/opt/ccnq3/traces'

# Selection criteria for pcap files
find_time = '1 hour ago'
# Look for final replies to INVITE messages.
ngrep_query = '^SIP/2.0 [2-6].*CSeq: [0-9]+ INVITE'
# ngrep output mode (must match regex)
ngrep_mode = 'single'

@analyze = (cb) ->
  return unless config.traces?.interfaces?.length > 0

  trace_dir = config.traces.workdir ? default_workdir

  for intf in config.traces.interfaces
    do (intf) ->

      cmd = """
      (
        find '#{trace_dir}' -type f -name '#{intf}*.pcap'    -newermt '#{find_time}' -print0 | \
        xargs -0 -I 'FILE' -r -P 4 -n 1 \
        ngrep -I FILE          -t -n -l -q -W '#{ngrep_mode}' '#{ngrep_query}'; \
        find '#{trace_dir}' -type f -name '#{intf}*.pcap.gz' -newermt '#{find_time}' -print0 | \
        xargs -0 -I 'FILE' -r -P 4 -n 1 \
        zcat FILE | ngrep -I - -t -n -l -q -W '#{ngrep_mode}' '#{ngrep_query}'; \
      )
      """

      child = exec cmd,
        stdio: ['ignore','pipe','ignore']

      stream = byline child.stdout

      stream.on 'data', (line) ->
        m = line.match /^. (\S+ \d\d:\d\d)\S+ (\S+) -> (\S+) SIP\/2.0 (\d{3})/
        data = { intf }
        data[key] = m[i] for key, i in fields
        # Do something with data
        cb data
