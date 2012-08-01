#!/usr/bin/env coffee

child_process = require 'child_process'

default_filesize = 10000
default_ringsize = 50
default_workdir = '/opt/ccnq3/traces'
default_filter = [
  'udp portrange 5060-5299'
  'udp portrange 15060-15299'
  'icmp'
  'tcp portrange 5060-5299'
  'tcp portrange 15060-15299'
].join ' or '

require('ccnq3_config').get (config) ->

  return unless config.traces?.interfaces?.length > 0

  for intf in config.traces.interfaces
    do (intf) ->
      child_process.exec """
        daemon -n 'ccnq3_traces_#{intf}' -o daemon.debug -r -- \\
        /usr/bin/dumpcap \\
          -p -q -i #{intf} \\
          -b filesize:#{config.traces.filesize ? default_filesize} \\
          -b files:#{config.traces.ringsize ? default_ringsize} \\
          -w #{config.traces.workdir ? default_workdir}/#{intf}.pcap \\
          -f "#{config.traces.filter ? default_filter}"
      """, stdio: 'ignore'
