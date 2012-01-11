#!/usr/bin/env coffee

dns = require "./dns"
Zone = dns.Zone
Zones = dns.Zones
EnumZone = require('./enum').EnumZone

configure = (db,uri,server) ->

  zones = new Zones()

  # Enumerate the domains listed in the database with a "records" field.
  options =
    uri: "/_design/dns/_view/domains?include_docs=true"

  db.req options, (r) ->

    for rec in r.rows ? []
      do (rec) ->
        doc = rec.doc
        return if not doc?
        if doc.ENUM
          zone = new EnumZone doc.domain, uri, doc
        else
          zone = new Zone doc.domain, doc
        zones.add_zone zone

    # Add any other records (hosts, ..)
    options =
      uri: "/_design/dns/_view/names"

    db.req options, (r) ->

      for rec in r.rows ? []
        do (rec) ->
          domain = rec.key
          zone = zones.get_zone(domain) ? zones.add_zone new Zone domain, {}
          zone.add_record rec.value

      server.reload zones


cdb = require 'cdb'
cdb_changes = require 'cdb_changes'

require('ccnq3_config').get (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  provisioning = cdb.new provisioning_uri

  server = dns.createServer()

  # Initial configuration
  configure provisioning, provisioning_uri, server

  server.listen(53053)

  options =
    uri: provisioning_uri
    filter_name: "dns/changes"

  cdb_changes.monitor options, (r) ->
    # Reconfigure on changes
    configure provisioning, provisioning_uri, server
