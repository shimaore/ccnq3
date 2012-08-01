# Analyze PCAP captures (up to one hour) and generate one-per-line JSON records
# specifying the response codes to INVITE queries.
# Note: re-INVITEs are treated the same as initial INVITEs.
# Note: records may be outside the one-hour window. Filter unwanted records.

byline = require 'byline'

default_workdir = '/opt/ccnq3/traces'

# Selection criteria for pcap files
find_time = '1 hour ago'
# Look for final replies to INVITE messages.
ngrep_filter = '^SIP/2.0 [2-6].*CSeq: [0-9]+ INVITE'

@analyze = (cb) ->

  self = packet_server
    interfaces: config.traces.interfaces
    format: 'json'
    trace_dir: config.traces?.workdir ? default_workdir
    find_filter: "-newermt '#{find_time}'"
    ngrep_filter: ngrep_filter

  self.on 'data', cb
