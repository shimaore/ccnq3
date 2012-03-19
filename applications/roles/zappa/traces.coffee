@include = ->
  # traces_proxy
  # A proxy to access opened traces servers.
  request = require 'request'

  @get '/roles/traces/:host/:port', ->

    if @session.roles.indexOf 'access:traces:' < 0
      return error:'Unauthorized'

    proxy = request
      uri: "http://#{@request.param 'host'}:#{@request.param 'port'}"
      jar: false
      timeout: 30000
    , (e) -> if e? then console.log e
    proxy.pipe @response
    return
