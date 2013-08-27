#!/usr/bin/env coffee

default_max_length = 500

GLOBAL_HEADER_LENGTH = 24
PACKET_HEADER_LENGTH = 16

module.exports = (input_stream = process.stdin, output_stream = process.stdout, max_length = default_max_length) ->
  pcapp = require 'pcap-parser'
  parser = pcapp.parse input_stream

  stash = []
  globalHeader = null
  parser.on 'globalHeader', (o) ->
    globalHeader = o
  parser.on 'packet', (packet) ->
    if stash.length > max_length
      stash.shift()
    stash.push packet

  parser.on 'end', ->
    # Global Header
    b = new Buffer GLOBAL_HEADER_LENGTH
    b.writeUInt32LE 0xa1b2c3d4, 0
    b.writeUInt16LE 2, 4
    b.writeUInt16LE 4, 6
    b.writeUInt32LE globalHeader.gmtOffset, 8
    b.writeUInt32LE globalHeader.timestampAccuracy, 12
    b.writeUInt32LE globalHeader.snapshotLength, 16
    b.writeUInt32LE globalHeader.linkLayerType, 20
    output_stream.write b

    while stash.length > 0
      packet = stash.shift()

      # Packet Header
      b = new Buffer PACKET_HEADER_LENGTH
      b.writeUInt32LE packet.header.timestampSeconds, 0
      b.writeUInt32LE packet.header.timestampMicroseconds, 4
      b.writeUInt32LE packet.header.capturedLength, 8
      b.writeUInt32LE packet.header.originalLength, 12
      output_stream.write b

      output_stream.write packet.data
