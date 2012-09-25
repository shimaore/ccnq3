###
# (c) 2010 Stephane Alnet
# Released under the AGPL3 license
###

@include = ->

  # Based on chriso / node-validator .. which throws, sadly enough.
  # Also it's missing raw IPv6 support.
  email_regex = ///
    ^
    (?:[\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+\.)*
       [\w\!\#\$\%\&\'\*\+\-\/\=\?\^\`\{\|\}\~]+
    @
    (?:
      (?:
        (?:[a-zA-Z0-9](?:[a-zA-Z0-9\-](?!\.)){0,61}[a-zA-Z0-9]?\.)+
        [a-zA-Z0-9]
        (?:[a-zA-Z0-9\-](?!$)){0,61}
        [a-zA-Z0-9]?
      )
      |
      (?:
        \[
          (?:(?:[01]?\d{1,2}|2[0-4]\d|25[0-5])\.){3}(?:[01]?\d{1,2}|2[0-4]\d|25[0-5]) # IPv4
        \]
      )
    )
    $
  ///

  pico = require 'pico'

  config = null
  require('ccnq3').config (c) ->
    config = c

  uuid = require 'node-uuid'

  @put '/ccnq3/portal/register.json': ->

    profile = @body
    for k,v of profile when k.match /^_/
      delete profile[k]

    # Assumes username = email
    email = @request.param 'email'
    if not email?
      return @send error:'Missing email.'
    if not email.match email_regex
      return @send error:'Invalid email.'

    username = email

    # Insert record
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
