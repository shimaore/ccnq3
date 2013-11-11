#!/usr/bin/env coffee

GLOBAL_HEADER_LENGTH = 24
PACKET_HEADER_LENGTH = 16

pcapp = require 'pcap-parser'

module.exports =
  tail: (input_stream,regex,max_length,stash = [],cb) ->

    if regex? and typeof regex is 'string'
      regex = new RegExp regex, 'm'

    parser = pcapp.parse input_stream

    parser.on 'globalHeader', (o) ->
      stash.globalHeader ?= o

    parser.on 'packet', (packet) ->
      if regex? and not packet.data.toString('ascii').match regex
        return
      stash.push packet
      if stash.length > max_length
        stash.shift()
      return

    parser.on 'end', ->
      cb stash

  write: (output_stream,stash,last) ->

    write_packet = (packet,cb) ->
      # Packet Header
      b = new Buffer PACKET_HEADER_LENGTH
      b.writeUInt32LE packet.header.timestampSeconds, 0
      b.writeUInt32LE packet.header.timestampMicroseconds, 4
      b.writeUInt32LE packet.header.capturedLength, 8
      b.writeUInt32LE packet.header.originalLength, 12
      output_stream.write b
      if output_stream.write packet.data
          do cb
      else
        output_stream.once 'drain', cb
      return

    # Global Header
    b = new Buffer GLOBAL_HEADER_LENGTH
    b.writeUInt32LE 0xa1b2c3d4, 0
    b.writeUInt16LE 2, 4
    b.writeUInt16LE 4, 6
    b.writeUInt32LE stash.globalHeader?.gmtOffset ? 0, 8
    b.writeUInt32LE stash.globalHeader?.timestampAccuracy ? 0, 12
    b.writeUInt32LE stash.globalHeader?.snapshotLength ? 65535, 16
    b.writeUInt32LE stash.globalHeader?.linkLayerType ? 1, 20
    output_stream.write b

    do next = ->
      return if stash.completed
      if stash.length > 0
        packet = stash.shift()
        write_packet packet, next
      else
        stash.completed = true
        output_stream.end last
      return
    return
