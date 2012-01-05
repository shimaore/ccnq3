#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

# See
#   http://wiki.freeswitch.org/wiki/Mod_enum
# for FreeSwitch usage.

ndns = require './ndns'
server = ndns.createServer 'udp4'

BIND_PORT = 53053
TTL = 30

server.on "request", (req, res) ->
  res.setHeader(req.header)

  res.addQuestion _ for _ in req.q

  if req.q.length > 0
    name = req.q[0].name
    if number = name.match(/^([\d.]+)\./)?[1]
      number = number.split('.').reverse().join('')
      console.log "Number = #{number}"
      loopback_uri = "sip:#{number}@server.example.net"
      account = "987654678"
      res.header.qr = 1
      res.header.ra = 1
      res.header.rd = 0
      res.header.ancount = 2 # or 1
      res.header.nscount = 0
      res.header.arcount = 0
      res.addRR name, TTL, "IN", "NAPTR", 10, 100, "u", "E2U+sip", "!^.*$!#{loopback_uri};account=#{account}!", ""
      res.addRR name, TTL, "IN", "NAPTR", 20, 100, "u", "E2U+account", "!^.*$!#{account}!", ""
      # In FreeSwitch XML, retrieve the account from enum_route_2, or use
      #   http://wiki.freeswitch.org/wiki/Misc._Dialplan_Tools_regex
      # to parse enum_route_1.
    res.send()

server.bind(BIND_PORT)

###
  named.conf:

    masters enum.example.net {
      127.0.0.1 port 53053;
    };

###
