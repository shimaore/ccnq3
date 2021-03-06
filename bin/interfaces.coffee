#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

## interfaces.coffee
# This script will print out a JSON document
# containing IPv4 and IPv6 public addresses for
# the local host.
# This is used by the bootstrap.sh script to
# initialize the config.interfaces parameter.

module.exports = ->
  interfaces = require('os').networkInterfaces()
  {v4_loopback,v6_linklocal} = require './classify-ip'

  result = {}

  for intf, r1 of interfaces
    do (intf,r1) ->
      for _ in r1
        do (_) ->
          # Skip internal addresses
          return if _.internal
          family = _.family.toLowerCase()
          address = _.address
          t = result[intf] ? {}

          # Skip local addresses (127/8, fe80::, etc.)
          switch family
            when 'ipv4'
              return if v4_loopback address
            when 'ipv6'
              return if v6_linklocal address

          # Another address for the same interface+family
          if t[family]?
            t.next ?= 0
            t.next++
            name = intf+'-'+t.next
            result[name] =
              address:address
          else
            t[family] = address
          result[intf] = t

  return result
