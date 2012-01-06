#
# Based on appload/dns
# with async loading
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
    @select_class "SOA", (d) =>
      if d.length == 0
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

  add_ns_records: (cb) ->
    @zone.select_class "NS", (d) =>
      @add_authoritative d
      cb()

  add_additionals: (cb) ->
    for record in _.union(@answer, @authoritative)
      do (record) =>
        for zone in @zones
          do (zone) =>
            old_cb = cb
            cb = => zone.find "A", record.value, (d) =>
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

class DNS

  constructor: (zones) ->
    @server = ndns.createServer('udp4')
    @server.on 'request', @resolve
    @port or= 53
    @reload zones or []

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
      if zone = _.find(@zones, ((zone) -> zone.handles name))
        response = new Response(name, type, zone, @zones)
        response.resolve (r) -> r.commit(req, res)
    res.send()

  close: ->
    @server.close()

exports.createServer = (config...) ->
  new DNS(config...)
