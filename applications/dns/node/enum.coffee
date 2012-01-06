#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

# See
#   http://wiki.freeswitch.org/wiki/Mod_enum
# for FreeSwitch usage.

require './dns'

cdb = require 'cdb'

make_id = (t,n) -> [t,n].join ':'

# Options should contain provisioning_uri
#  provisioning_uri = config.provisioning.local_couchdb_uri

class EnumZone extends Zone
require('ccnq3_config').get (config) ->

  record_defaults: ->
    ttl: @ttl or 60
    class: "NAPTR"
    value: ""

  select: (type,name) ->
    return unless type is 'NAPTR'
    return unless number = name.match(/^([\d.]+)\./)?[1]

    number = number.split('.').reverse().join('')

    provisioning.get make_id('number',number), (r) ->
      if r.inbound_uri?
        # Add RRs
        res.addRR name, ttl, "IN", "NAPTR", 10, 100, "u", "E2U+sip", "!^.*$!#{r.inbound_uri}!", ""
        res.header.ancount++
        res.addRR name, ttl, "IN", "NAPTR", 20, 100, "u", "E2U+account", "!^.*$!#{r.account}!", ""
        res.header.ancount++
        # In FreeSwitch XML, retrieve the account from enum_route_2.
      res.send()

  handles: (domain) ->
    domain = @dotize(domain)
    if domain is @dot_domain
      return true
    if domain.match(/^[\d.]+\.(.*)+$/)?[1] is @dot_domain
      return true
    false
