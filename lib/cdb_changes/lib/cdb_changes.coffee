###
# (c) 2010 Stephane Alnet
# Released under the GPL3 license
###

util = require 'util'
url = require 'url'
json_req = require 'json_req'

# Reference for request: https://github.com/mikeal/node-utils/tree/master/request

# Changes API: http://wiki.apache.org/couchdb/HTTP_database_API#Changes
# and also:    http://guide.couchdb.org/draft/notifications.html


cdb_changes = exports

# monitor ( uri: cdb_uri,filter_name,[filter_params,[since]],cb)
# options should be:
#    uri
#    filter_name
#    filter_params
#    since
#    cookie

cdb_changes.monitor = (options,cb)->

  # Stream to receive the data from CouchDB
  parser = new process.EventEmitter()

  parser.buffer = ""

  parser.writable = true

  parser.write = (chunk,encoding) ->
    parser.buffer += chunk.toString(encoding)

    d = parser.buffer.split("\n")
    while d.length > 1
      line = d.shift()

      # Processing line
      try
        p = JSON.parse line
      catch error
        util.log "JSON did not parse #{line}: #{error}"
      if p?.id?
        cb p
      # /Processing line

    parser.buffer = d[0]

    return true

  parser.end = ->
    util.log("#{options.uri} closed, attempting restart")
    # Automatically restart
    cdb_changes.monitor(options,cb)

  # Send the request

  uri = url.parse options.uri
  # Delete the computed values
  delete uri.href
  delete uri.host
  delete uri.search
  # And re-build
  uri.pathname += '/_changes'
  uri.query =
    feed: 'continuous'
    heartbeat: 10000
    include_docs: if options.include_docs? then options.include_docs else true

  uri.query.filter = options.filter_name if options.filter_name?
  uri.query.since  = options.since       if options.since?
  uri.query.limit  = options.limit       if options.limit?
  uri.query[k] = v for k, v of options.filter_params?

  options =
    uri: url.format uri
    header:
      cookie: options.cookie

  cdb_stream = json_req.request options, (r) ->
    if r.error?
      util.log(r.error)

  cdb_stream.pipe(parser)
