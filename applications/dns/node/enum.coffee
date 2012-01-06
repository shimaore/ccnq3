#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

# See
#   http://wiki.freeswitch.org/wiki/Mod_enum
# for FreeSwitch usage.

Zone = require('./dns').Zone

cdb = require 'cdb'

make_id = (t,n) -> [t,n].join ':'

# Options should contain provisioning_uri
#  provisioning_uri = config.provisioning.local_couchdb_uri

exports.EnumZone = class EnumZone extends Zone

  select: (type,name,cb) ->
    return cb() unless type is 'NAPTR'
    return cb() unless number = name.match(/^([\d.]+)\./)?[1]

    number = number.split('.').reverse().join('')

    provisioning.get make_id('number',number), (r) ->
      if r.inbound_uri?
        cb [
          {class: "NAPTR", value: [10,100,'u','E2U+sip',"!^.*$!#{r.inbound_uri}!", ""]}
          {class: "NAPTR", value: [20,100,'u','E2U+account', "!^.*$!#{r.account}!", ""]}
        ]
        # In FreeSwitch XML, retrieve the account from enum_route_2.
      else
        cb()

  # The regular "handles" should work but is recursive and could be slow for ENUM.
  handles: (domain) ->
    domain = @dotize(domain)
    if domain is @dot_domain
      return true
    if domain.match(/^[\d.]+\.(.*)+$/)?[1] is @dot_domain
      return true
    false
