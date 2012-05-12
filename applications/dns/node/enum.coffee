#!/usr/bin/env coffee
# (c) 2012 Stephane Alnet

# See
#   http://wiki.freeswitch.org/wiki/Mod_enum
# for FreeSwitch usage.

Zone = require('./dns').Zone

pico = require 'pico'

make_id = (t,n) -> [t,n].join ':'

exports.EnumZone = class EnumZone extends Zone

  constructor: (domain, @provisioning_uri, options) ->
    super domain, options

  select: (type,name,cb) ->
    unless type is 'NAPTR' and prefix = name.match(/^([\d.]+)\./)?[1]
      return super type, name, cb

    number = prefix.split('.').reverse().join('')

    provisioning = pico @provisioning_uri
    provisioning.retrieve make_id('number',number), (error,response,doc) =>
      if not error and doc.inbound_uri?
        cb [
          @create_record
            prefix: prefix
            ttl: @ttl
            class: "NAPTR"
            value: [10,100,'u','E2U+sip',"!^.*$!#{doc.inbound_uri}!", ""]
          @create_record
            prefix: prefix
            ttl: @ttl
            class: "NAPTR"
            value: [20,100,'u','E2U+account', "!^.*$!#{doc.account}!", ""]
        ]
        # In FreeSwitch XML, retrieve the account from enum_route_2.
      else
        cb []
