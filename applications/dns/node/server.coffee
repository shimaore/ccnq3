#!/usr/bin/env coffee

dns = require "./dns"
Zone = dns.Zone
Zones = dns.Zones
EnumZone = require('./enum').EnumZone

configure = (db,server) ->

  console.log "Loading zones"

  zones = new Zones()

  # Enumerate the domains listed in the database with a "records" field.
  db.view 'dns', 'domains', qs:{include_docs:true}, (e,r,b) ->

    for rec in b.rows ? []
      do (rec) ->
        doc = rec.doc
        return if not doc?
        if doc.ENUM
          zone = new EnumZone doc.domain, db.prefix(), doc
        else
          zone = new Zone doc.domain, doc
        zones.add_zone zone

    # Add any other records (hosts, ..)
    db.view 'dns', 'names', (e,r,b) ->

      for rec in b.rows ? []
        do (rec) ->
          domain = rec.key
          zone = zones.get_zone(domain) ? zones.add_zone new Zone domain, {}
          zone.add_record rec.value

      server.reload zones

    return


pico = require 'pico'

require('ccnq3_config') (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = pico provisioning_uri

  server = dns.createServer()

  # Initial configuration
  configure provisioning, server

  server.listen(53053)

  options =
    since_name: "dns #{config.host}"
    filter_name: "dns/changes"

  provisioning.monitor options, (r) ->
    # Reconfigure on changes
    configure provisioning, server
