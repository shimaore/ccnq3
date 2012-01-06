#!/usr/bin/env coffee
#
dns = require "./dns"
Zone = dns.Zone
EnumZone = require('./enum').EnumZone

zones = [
  # Shorter one first
  new Zone( 'example.net',
    admin: 'bob.example.net'
    records: [
      {class:'NS', value:'ns1.example.net.'}
      {class:'NS', value:'ns2.example.net.'}
      {prefix:'ns1',value:'127.0.0.1'}
      {prefix:'ns2',value:'127.0.0.1'}
      {prefix:'_sip._udp',class:'SRV',value:[20,7,"sip1.example.net."]}
    ]
  )
  new EnumZone( 'enum.example.net',
    ttl: 60
    admin: 'bob.example.net'
    records: [
      {class:'NS', value:'ns1.example.net.'}
      {class:'NS', value:'ns2.example.net.'}
    ]
  )
  new Zone( 'private.example.net',
    admin: 'bob.example.net'
    records: [
      {class:'NS', value:'ns1.example.net.'}
      {class:'NS', value:'ns2.example.net.'}
      {prefix:'s1',value:'192.168.1.210'}
    ]
  )
]

server = dns.createServer(zones)
server.listen(53053)
