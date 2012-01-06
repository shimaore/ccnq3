#
# Based on appload/dns
# with extensions for ccnq3 Carrier-ENUM
#
dgram = require('dgram')
ndns = require('./ndns')
_ = require("underscore")

exports.Zone = class Zone

  constructor: (domain, options) ->
    @domain = @undotize(domain)
    @dot_domain = @dotize(domain)
    @set_options(options)
    @records = (@create_record(record) for record in options.records or [])
    if @select_class("SOA").length == 0
      @add_default_soa()

  add_default_soa: ->
    @records.push @create_soa()

  defaults: ->
    ttl: 1200
    serial: 2011072101   # serial (YYYYMMDDrr)
    refresh: 1800        # refresh (30 minutes)
    retry: 900           # retry (15 minutes)
    expire: 1209600      # expire (2 weeks)
    min_ttl: 1200        # minimum TTL (20 minutes)
    admin: "hostmaster.#{@domain}."

  record_defaults: ->
    ttl: @ttl or @defaults().ttl
    class: "A"
    value: "" 

  dotize: (domain) ->
    if domain[-1..] == "." then domain else domain + "."

  undotize: (domain) ->
    if domain[-1..] != "." then domain else domain[..-2]

  set_options: (options) ->
    defaults = @defaults()
    for key, val of defaults
      @[key] = options[key] or val

    @admin = @dotize(@admin)

  create_record: (record) ->
    r = _.extend(_.clone(@record_defaults()), record)
    r.name = if r.prefix? then @dotize(r.prefix) + @dot_domain else @dot_domain
    r

  select_class: (type) ->
    _(@records).filter (record) -> record.class == type

  find_class: (type) ->
    _(@records).find (record) -> record.class == type

  select: (type, name, cb) ->
    cb _(@records).filter (record) -> (record.class == type) and (record.name == name)

  find: (type, name) ->
    _(@records).find (record) -> (record.class == type) and (record.name == name)

  create_soa: ->
    keys = "dot_domain admin serial refresh retry expire min_ttl"
    value = keys.split(" ").map((param) => @[param]).join(" ")
    {name: @dot_domain, @ttl, class: "SOA", value}

  handles: (domain) ->
    domain = @dotize(domain)
    if domain == @dot_domain
      true
    else if domain.length > @dot_domain.length
      @handles(domain.split(".")[1...].join("."))
    else
      false

class Response
  constructor: (name, @type, @zone, @zones) ->
    @name = @zone.dotize name
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

  add_ns_records: ->
    @add_authoritative @zone.select_class "NS"

  add_additionals: ->
    for record in _.union(@answer, @authoritative)
      for zone in @zones
        @add_additional zone.find "A", record.value

  add_soa_to_authoritative: ->
    @add_authoritative @zone.find_class "SOA"

  resolve: ->
    # Request for A or NS or whatever, but CNAME as response
    if @add_answer @zone.select "CNAME", @name
    # NS
    else if @type == "NS" and @zone.select @type, @name, @add_answer
    # A, TXT, MX
    else if @add_answer @zone.select @type, @name, ->
      @add_ns_records()
    # empty response, SOA in authoritative section
    else
      @add_soa_to_authoritative()

    # always add additional records if there are any useful
    @add_additionals()
    @

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

class DNS

  constructor: (zones) ->
    @server = ndns.createServer('udp4')
    @server.on 'request', @resolve
    @port or= 53
    @reload zones or {}

  reload: (zones) ->
    @zones = zones
    # @zones = (new Zone(key, val) for key, val of zones)

  listen: (port) ->
    @server.bind port or @port

  resolve: (req, res) =>
    res.setHeader(req.header)
    for q in req.q
      res.addQuestion(q)

    if req.q.length > 0
      name = req.q[0].name
      type = req.q[0].typeName
      if zone = _.find(@zones, ((zone) -> zone.handles name))
        console.log "zone found", zone.dot_domain
        response = new Response(name, type, zone, @zones)
        response.resolve().commit(req, res)
    res.send()

  close: ->
    @server.close()

exports.createServer = (config...) ->
  new DNS(config...)
