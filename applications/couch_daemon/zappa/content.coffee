@include = ->

  @use 'bodyParser'

  # This is modeled after connect/lib/middleware/basicAuth.js
  utils = require('connect').utils
  unauthorized = utils.unauthorized

  @use (req,res,next) ->
    authorization = req.headers.authorization
    realm = 'couchdb' # Should match couchdb realm, ideally
    if req.user
      return next()
    if not authorization
      return unauthorized res, realm
    parts = authorization.split ' '
    if parts.length isnt 2
      return next utils.error 400
    scheme = parts[0]
    credentials = new Buffer(parts[1],'base64').toString().split(':')
    user = credentials[0]
    pass = credentials[1]

    if scheme isnt 'Basic'
      return next utils.error 400

    req.user = user
    req.pass = pass
    do next

  @helper
    failure: (o) ->
      @res.statusCode = 500
      @json o

    success: (o) ->
      o.ok = true
      @json o

  @get '/_ccnq3', ->
    @success welcome:'ccnq3'

  fs = require 'fs'
  path = require 'path'
  fs.readdir './include', (err,names) =>
    return if err
    for name in names
      if name.match /\.coffee$/
        @include path.join './include', name

  return
