#!/usr/bin/env coffee

dns = require "./dns"
Zone = dns.Zone
EnumZone = require('./enum').EnumZone

cdb = require 'cdb'

require('ccnq3_config').get (config) ->

  # Enumerate the domains listed in the database with a "records" field.
  options =
    uri: "/_design/dns/_view/domains?include_docs=true"

  cdb.new(config.provisioning.local_couchdb_uri).req options, (r) ->

    server = dns.createServer(zones)

    for rec in r.rows
      do (rec) ->
        doc = rec.doc
        return if not doc?
        if doc.ENUM
          zone = new EnumZone doc.domain, config.provisioning.local_couchdb_uri, doc
        else
          zone = new Zone doc.domain, doc
        server.add_zone zone

    # Add any other records (hosts, ..)

    server.listen(53053)

###
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
###
