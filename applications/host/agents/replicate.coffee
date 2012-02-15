# Initiate replication (_replicator does not work).
replicate = (config) ->

  # provisioning.local_couchdb_uri MUST be "http://127.0.0.1:5984/provisioning"
  expected = "http://127.0.0.1:5984/provisioning"
  source_uri = config.provisioning.host_couchdb_uri
  target_uri = config.provisioning.local_couchdb_uri

  if target_uri isnt expected
    console.log "provisioning.local_couchdb_uri should be #{expected}"
    return
  if not source_uri
    console.log "provisioning.host_couchdb_uri is required"
    return

  replicator = "http://127.0.0.1:5984/_replicate"
  replicant =
    # _id:    'ccnq3_provisioning'   # Only when using _replicator
    source: source_uri
    target: 'provisioning' # local target
    continuous: true

  # Still a bug? CouchDB replication can't authenticate properly, the Base64 contains %40 litteraly...
  url = require 'url'
  qs = require 'querystring'
  source = url.parse replicant.source
  replicant.source = url.format
    protocol: source.protocol
    hostname: source.hostname
    port:     source.port
    pathname: source.pathname

  [username,password] = source.auth?.split /:/
  username = qs.unescape username if username?
  password = qs.unescape password if password?

  if username? or password?
    username ?= ''
    password ?= ''
    basic = new Buffer("#{username}:#{password}")
    replicant.source =
      url: replicant.source
      headers:
        "Authorization": "Basic #{basic.toString('base64')}"
  # /CouchDB bug

  cdb = require 'cdb'
  cdb.new(replicator).post replicant

exports.replicate = (config) ->
  if config.admin?.system
    console.log "Not replicating from manager"
  else
    replicate config
