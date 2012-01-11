#
# Based on appload/dns
# with async loading
# and other changes for ccnq3
#
dgram = require('dgram')
ndns = require('./ndns')
_ = require("underscore")

dotize = (domain) ->
  if domain[-1..] == "." then domain else domain + "."

undotize = (domain) ->
  if domain[-1..] != "." then domain else domain[..-2]

get_serial = ->
  now = new Date()
  date = now.toJSON().replace(/[^\d]/g,'').slice(0,8)
  seq = Math.floor(100*(now.getHours()*60+now.getMinutes())/1440)
  seq = if seq < 10 then '0'+seq else ''+seq
  serial = date + seq

exports.Zone = class Zone

  constructor: (domain, options) ->
    @domain = undotize(domain)
    @dot_domain = dotize(domain)
    @set_options(options)
    @records = (@create_record(record) for record in options.records or [])
    @select_class "SOA", (d) =>
      if d.length == 0
        @add_default_soa()

  add_default_soa: ->
    @records.push @create_soa()

  add_record: (record) ->
    @records.push @create_record record

  defaults: ->
    ttl: 420
    serial: get_serial() # serial (YYYYMMDDrr)
    refresh: 840         # refresh (30 minutes)
    retry: 900           # retry (15 minutes)
    expire: 1209600      # expire (2 weeks)
    min_ttl: 1200        # minimum TTL (20 minutes)
    admin: "hostmaster.#{@domain}."

  record_defaults: ->
    ttl: @ttl or @defaults().ttl
    class: "A"
    value: ""

  set_options: (options) ->
    defaults = @defaults()
    for key, val of defaults
      @[key] = options[key] or val

    @admin = dotize(@admin)

  create_record: (record) ->
    r = _.extend(_.clone(@record_defaults()), record)
    r.name = if r.prefix? then dotize(r.prefix) + @dot_domain else @dot_domain
    r

  select_class: (type,cb) ->
    cb _(@records).filter (record) -> record.class == type

  find_class: (type,cb) ->
    cb _(@records).find (record) -> record.class == type

  select: (type, name, cb) ->
    cb _(@records).filter (record) -> (record.class == type) and (record.name == name)

  find: (type, name, cb) ->
    cb _(@records).find (record) -> (record.class == type) and (record.name == name)

  create_soa: ->
    keys = "dot_domain admin serial refresh retry expire min_ttl"
    value = keys.split(" ").map((param) => @[param]).join(" ")
    {name: @dot_domain, @ttl, class: "SOA", value}


class Response
  constructor: (name, @type, @zone, @server) ->
    @name = dotize name
    @answer = []
    @authoritative = []
    @additional = []
    #TODO response record limit 18

  add: (obj, to) ->
    if obj? and not _(obj).isEmpty()
      if _(obj).isArray()
        for o in obj
          to.push o
      else
        to.push obj
      true
    else
      false

  add_answer: (record) ->
    @add(record, @answer)

  add_authoritative: (record) ->
    @add(record, @authoritative)

  add_additional: (record) ->
    @add(record, @additional)

  add_ns_records: (cb) ->
    @zone.select_class "NS", (d) =>
      @add_authoritative d
      cb()

  add_additionals: (cb) ->
    for record in _.union(@answer, @authoritative)
      do (record) =>
        name = record.value
        # Only do the resolution for explicit names (e.g. CNAME, NS)
        return unless typeof name is 'string'
        zone = @server.zones?.find_zone name
        # Nothing to add if we don't know about that zone.
        return unless zone?

        old_cb = cb
        cb = => zone.find "A", name, (d) =>
          @add_additional d
          old_cb()
    cb()

  add_soa_to_authoritative: (cb) ->
    @zone.find_class "SOA", (d) =>
      @add_authoritative d
      cb()

  resolve: (cb) ->
    finalize = =>
      # always add additional records if there are any useful
      @add_additionals =>
        cb @

    # If a CNAME answer is available, always provide it.
    @zone.select "CNAME", @name, (d) =>
      if @add_answer d
        return finalize()

      # No CNAME, lookup record
      @zone.select @type, @name, (d) =>
        if @add_answer d
          if @type == "NS"
            finalize()
          else
            @add_ns_records finalize
        else
          # empty response, SOA in authoritative section
          @add_soa_to_authoritative finalize

  commit: (req, res) ->
    ancount = @answer.length
    nscount = @authoritative.length
    arcount = @additional.length

    for key, val of { qr: 1, ra: 0, rd: 1, aa: 1, ancount, nscount, arcount }
      res.header[key] = val

    for record in _.union(@answer, @authoritative, @additional)
      value = if _(record.value).isArray() then record.value else record.value.split " "
      res.addRR record.name, record.ttl, "IN", record.class, value...
    @

exports.Zones = class Zones

  constructor: ->
    @zones = {}

  # Explicit: add_zone returns the zone
  add_zone: (zone) ->
    @zones[zone.dot_domain] = zone

  find_zone: (domain) ->
    domain = dotize domain
    if @zones[domain]?
      return @zones[domain]
    else
      if domain is '.'
        return
      else
        return @find_zone domain.split(".")[1...].join(".")

  get_zone: (domain) ->
    domain = dotize domain
    @zones[domain]


class DNS

  constructor: (zones) ->
    @server = ndns.createServer('udp4')
    @server.on 'request', @resolve
    @port or= 53
    @reload zones

  reload: (zones) ->
    @zones = zones

  listen: (port) ->
    @server.bind port or @port

  resolve: (req, res) =>
    res.setHeader(req.header)
    for q in req.q
      res.addQuestion(q)

    if req.q.length > 0
      name = req.q[0].name
      type = req.q[0].typeName
      if zone = @zones?.find_zone name
        response = new Response(name, type, zone, @)
        response.resolve (r) ->
          r.commit(req, res)
          res.send()
        return
    res.send()

  close: ->
    @server.close()

exports.createServer = (config...) ->
  new DNS(config...)
exports.dotize = dotize
exports.undotize = undotize
