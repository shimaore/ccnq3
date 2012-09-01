#!/usr/bin/env coffee
###
(c) 2010 Stephane Alnet
Released under the AGPL3 license
###

esl = require 'esl'
util = require 'util'
request = require('request').defaults timeout:500

##
# Expected to be used with:
#
#   <action application="set" data="socket_resume=true"/>
#   <action application="socket" data="127.0.0.1:7124 async full"/>
#
require('ccnq3_config') (config)->

  # esl.debug = true
  cnam_uri = config.cnam_client?.uri ? 'https://cnam.sotelips.net:9443/1'

  server = esl.createCallServer()

  server.on 'CONNECT', (call) ->

    cid = call.body?['Caller-Caller-ID-Number'] ? ''

    x = cid.match /^[+]?1?(\d{10})$/
    if x?
      number = x[1]
      request.get cnam_uri+number, (e,r,b) ->
        data = ''
        if not e?
          data = b
        data = data.replace /[^\w,.@-]/g, ' '
        data = data.replace /\s+$/g, ''
        call.command 'set', "effective_caller_id_name=#{data}", (call) ->
          call.end()
    else
      call.end()

  server.listen config.cnam_client?.port ? 7124
