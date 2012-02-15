###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

querystring = require 'querystring'
util = require 'util'
request = require('request').defaults jar:false

class cdb
  constructor: (@db_uri) ->

  req: (options,cb) ->
    if options.uri?
      options.uri = @db_uri + '/' + options.uri
    else
      options.uri = @db_uri
    request options, (e,r,json) ->
      cb? json ? error:r.statusCode

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
        json: p
      @req options, (r)->
        if r.error? then return util.log r.error

  # Record-level operations

  head: (id,cb) ->
    request.head @db_uri + querystring.escape(id), (e,r) ->
      if r?.headers?.etag?
        rev = r.headers.etag
        rev = rev.replace /"/g, ''
        cb? {_rev:rev}
      else
        cb? {error:r.statusCode}

  get: (id,cb) ->
    options =
      uri: querystring.escape(id)
    @req options, cb

  put: (p,cb) ->
    options =
      uri:      querystring.escape(p._id)
      method:   'PUT'
      json:     p
    @req options, cb

  post: (p,cb) ->
    options =
      method:   'POST'
      json:     p
    @req options, cb

  del: (p,cb) ->
    options =
      uri:      querystring.escape(p._id)+'?rev='+querystring.escape(p._rev)
      method:   'DELETE'
    @req options, cb

@new = (db_uri) -> new cdb (db_uri)
