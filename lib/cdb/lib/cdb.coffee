###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

querystring = require 'querystring'
json_req = require 'json_req'
util = require 'util'

class cdb
  constructor: (@db_uri) ->

  req: (options,cb) ->
    if options.uri?
      options.uri = @db_uri + '/' + options.uri
    else
      options.uri = @db_uri
    json_req.request options, cb

  # Database-level operations

  exists: (cb) ->
    @req {}, (r) ->
      cb(r.db_name?)

  create: (cb) ->
    @req {method:'PUT'}, cb

  erase: (cb) ->
    @req {method:'DELETE'}, cb

  security: (cb) ->
    @get '_security', (p) =>
      if p.error? then return util.log p.error
      cb(p)
      options =
        method: 'PUT'
        uri: '_security'
        body: p
      @req options, (r)->
        if r.error? then return util.log r.error


  # Record-level operations

  get: (id,cb) ->
    options =
      uri: querystring.escape(id)
    @req options, cb

  put: (p,cb) ->
    options =
      uri:      querystring.escape(p._id)
      method:   'PUT'
      body:     p
    @req options, cb

  post: (p,cb) ->
    options =
      method:   'POST'
      body:     p
    @req options, cb

@new = (db_uri) -> new cdb (db_uri)
