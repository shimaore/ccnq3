###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

@include = ->
  pico = require 'pico'

  config = null
  require('ccnq3').config (c) ->
    config = c

  @post '/ccnq3/portal/recover.json': ->
    email = @body.email
    if not email?
      return @send error:'Missing username'

    users_db = pico config.users.couchdb_uri
    users_db.get "org.couchdb.user:#{email}", (e,r,p) =>
      if e?
        return @send error: 'Please make sure you register first.'

      # Everything is OK
      p.send_password = true
      users_db.put p, (e) =>
        if e?
          return @send error:e
        else
          return @send ok:true
