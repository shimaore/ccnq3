#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

require('ccnq3_config').get (config)->

  zappa = require 'zappa'
  zappa config.kayako_loginshare.port, config.kayako_loginshare.hostname, {config}, ->

    @use 'bodyParser'

    request = require 'request'

    kayako_error_msg = (msg) ->
      msg ?= 'Invalid Username or Password'
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <loginshare>
        <result>0</result>
        <message>#{msg}</message>
      </loginshare>
      """

    @post '/loginshare': ->
      q =
        method: 'POST'
        uri: config.kayako_loginshare.login_uri
        json:
          username: @body.username
          password: @body.password

      j = request.jar()
      request = request.defaults jar:j, json:true
      request q, (e,r,body) =>
        if e?
          return @send kayako_error_msg()

        request config.kayako_loginshare.profile_uri, (e,r,json) =>
          if e?
            return @send kayako_error_msg("Internal Error")

          @send """
               <?xml version="1.0" encoding="UTF-8"?>
               <loginshare>
                 <result>1</result>
                 <user>
                   <usergroup>Registered</usergroup>
                   <fullname>#{json.name}</fullname>
                   <emails>
                     <email>#{json.email}</email>
                   </emails>
                   <phone>#{json.phone}</phone>
                 </user>
               </loginshare>
               """
