###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

@include = ->

  pico = require 'pico'

  config = null
  require('ccnq3_config') (c) ->
    config = c

  uuid = require 'node-uuid'

  @put '/ccnq3/portal/register.json': ->

    profile = @body
    for k,v of profile when k.match /^_/
      delete profile[k]

    # Assumes username = email
    username = @request.param 'email'

    # Insert record
    if not username
      return @send error:'No username given'

    db = pico config.users.couchdb_uri
    db.request.get json:true, (e,r,b) =>
      if e or not b.db_name?
        return @send error:'Not connected to the database'

      p =
        _id: 'org.couchdb.user:'+username
        type: 'user'
        name: username
        roles: []
        domain: @request.header('Host').split(/:/)[0]
        profile: profile
        user_database: 'u'+uuid() # User's database UUID (or UUID prefix)
        send_password: true # send them their new password

      # PUT without _rev can only happen once
      db.put p, (e) =>
        if e?
          return @send error:e
        else
          if config.users.logged_in_after_initial_registration
            @session.logged_in = username
            @session.roles     = []
          return @send ok:true, username:p.name, domain:p.domain
