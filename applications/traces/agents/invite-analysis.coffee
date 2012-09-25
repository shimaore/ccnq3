# Analyze PCAP captures over the past 5 minutes and provides a data record
# specifying the repartition of response codes to INVITE queries.
# Note: re-INVITEs are treated the same as initial INVITEs.

packet_server = require './packet_server'

default_workdir = '/opt/ccnq3/traces'

##
# find_time: selection criteria for pcap files
analyze = (interfaces,find_time,ngrep_filter)->

  self = packet_server
    interfaces: config.traces.interfaces
    format: 'json'
    trace_dir: config.traces?.workdir ? default_workdir
    find_filter: "-newermt '#{find_time}'"
    ngrep_filter: ngrep_filter
    # tshark_filter is left empty

aggregate = (self,ago,cb) ->

  error = null
  result = {}

  start = new Date()

  self.on 'data', (data) ->
    time = new Date data["frame.time"]
    return unless 0 <= time-start < ago
    status = data["sip.Status-Code"]
    result[status] ?= 0
    result[status]++

  self.on 'end', ->
    cb error, result

# Look for final replies to INVITE messages.
ngrep_filter = '^SIP/2.0 [2-6].*CSeq: [0-9]+ INVITE'

minutes = 60*1000

## Do the INVITE response-code analysis for applications/monitor.
# cb = (error,data) -> ...
@invite_analysis = (since,cb) ->
  require('ccnq3').config (config) ->
    interfaces = config.traces?.interfaces
    if interfaces?.length > 0
      server = @analyze "#{since+1} minutes ago", ngrep_filter
      @aggregate server, since*minutes, cb
    else
      cb null, null
