#!/usr/bin/env coffee

dns = require "./dns"
Zone = dns.Zone
EnumZone = require('./enum').EnumZone

cdb = require 'cdb'

require('ccnq3_config').get (config) ->

  provisioning_uri = config.provisioning.local_couchdb_uri
  if not provisioning_uri?
    throw error:"config.provisioning.local_couchdb_uri is required"
  provisioning = cdb.new provisioning_uri

  # Enumerate the domains listed in the database with a "records" field.
  options =
    uri: "/_design/dns/_view/domains?include_docs=true"

  provisioning.req options, (r) ->

    server = dns.createServer()

    for rec in r.rows ? []
      do (rec) ->
        doc = rec.doc
        return if not doc?
        if doc.ENUM
          zone = new EnumZone doc.domain, config.provisioning.local_couchdb_uri, doc
        else
          zone = new Zone doc.domain, doc
        server.add_zone zone

    # Add any other records (hosts, ..)
    options =
      uri: "/_design/dns/_view/names"

    provisioning.req options, (r) ->

      for rec in r.rows ? []
        do (rec) ->
          domain = rec.key
          zone = server.get_zone(domain) ? server.add_zone new Zone domain, {}
          zone.add_record rec.value

      server.listen(53053)
