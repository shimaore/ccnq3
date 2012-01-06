#!/usr/bin/env coffee
#
dns = require "./dns"
Zone = dns.Zone
EnumZone = require('./enum').EnumZone

require('ccnq3_config').get (config) ->
  zones = [
    new EnumZone( 'enum.example.net', config.provisioning.local_couchdb_uri,
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
    # Shorter one last
    new Zone( 'example.net',
      admin: 'bob.example.net'
      records: [
        {class:'NS', value:'ns1.example.net.'}
        {class:'NS', value:'ns2.example.net.'}
        {prefix:'ns1',value:'127.0.0.1'}
        {prefix:'ns2',value:'127.0.0.1'}
        {prefix:'_sip._udp',class:'SRV',value:[20,7,5060,"sip1.example.net."]}
      ]
    )
  ]

  server = dns.createServer(zones)
  server.listen(53053)
