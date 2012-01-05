#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

# See
#   http://wiki.freeswitch.org/wiki/Mod_enum
# for FreeSwitch usage.

ndns = require './ndns'
cdb = require 'cdb'

make_id = (t,n) -> [t,n].join ':'

require('ccnq3_config').get (config) ->

  server = ndns.createServer 'udp4'

  ttl = config.inbound_enum?.ttl ? 60

  provisioning = cdb.new config.provisioning.local_couchdb_uri

  server.on "request", (req, res) ->
    res.setHeader req.header

    res.addQuestion _ for _ in req.q

    unless req.q.length > 0
      return res.send()

    name = req.q[0].name
    unless number = name.match(/^([\d.]+)\./)?[1]
      # Update headers
      res.header.qr = 1
      res.header.ra = 1
      res.header.rd = 0
      # res.header.aa = 1
      res.header.ancount = 0 # Will increment later
      res.header.nscount = 0
      res.header.arcount = 0
      res.addRR name,ttl,"IN","SOA",
                config.inbound_enum.soa,
                config.inbound_enum.soa,
                1, # Serial
                10*ttl, # Refresh
                10*ttl, # Retry
                3600, # Expire
                ttl  # Minimum TTL
      res.header.ancount++
      for ns in config.inbound_enum.ns
        do (ns) ->
          res.addRR name, 60, "IN", "NS", ns
          res.header.nscount++
      return res.send()

    number = number.split('.').reverse().join('')
    # console.log "Number = #{number}"

    provisioning.get make_id('number',number), (r) ->
      if r.inbound_uri?
        # Update headers
        res.header.qr = 1
        res.header.ra = 1
        res.header.rd = 0
        res.header.ancount = 0 # Will increment later
        res.header.nscount = 0
        res.header.arcount = 0
        # Add RRs
        res.addRR name, ttl, "IN", "NAPTR", 10, 100, "u", "E2U+sip", "!^.*$!#{r.inbound_uri}!", ""
        res.header.ancount++
        res.addRR name, ttl, "IN", "NAPTR", 20, 100, "u", "E2U+account", "!^.*$!#{r.account}!", ""
        res.header.ancount++
        # In FreeSwitch XML, retrieve the account from enum_route_2.
      res.send()

  server.bind config.inbound_enum?.port ? 53053

###
  named.conf:

    masters enum.example.net {
      127.0.0.1 port 53053;
    };

###
