##
# (c) 2012 Stephane Alnet
#

dgram = require 'dgram'
dns = require 'dns'
pico = require 'pico'

exports.notifier = (config) ->
  socket = dgram.createSocket 'udp4'

  send_notification_to = (number) ->
    number_domain = config.voicemail.number_domain ? 'local'

    provisioning_db = pico config.provisioning.local_couchdb_uri
    provisioning_db.get "number:#{number}@#{number_domain}", (e,r,b) ->
      if e? or not b.user_database? then return

      endpoint = b.endpoint
      user_db = pico config.voicemail.userdb_base_uri + '/' + b.user_database

      d = endpoint.match /^([^@]+)@([^@]+)$/
      if d
        domain_name = d[2]
        dns.resolveSrv '_sip._udp.' + domain_name, (e,addresses) ->
          if e? then return
          for address in addresses
            send_sip_notification address.port, address.name
      else
        # Currently no MWI to static endpoints
        return

      send_sip_notification = (target_port,target_name)->
        user_db.view 'voicemail', 'new_messages', (e,r,b) ->
          if e? then return

          body = new Buffer """
            Message-Waiting: #{if b.total_rows > 0 then 'yes' else 'no'}
          """

          # FIXME no tag, etc.
          headers = new Buffer """
            NOTIFY sip:#{endpoint} SIP/2.0
            Via: SIP/2.0/UDP #{target_name}:#{target_port};branch=0
            Max-Forwards: 2
            To: <sip:#{endpoint}>
            From: <sip:#{endpoint}>
            Call-ID: #{Math.random()}
            CSeq: 1 NOTIFY
            Event: message-summary
            Subscription-State: active
            Content-Type: application/simple-message-summary
            Content-Length: #{body.length}
            \n
          """.replace /\n/g, "\r\n"

          message = new Buffer headers.length + body.length
          headers.copy message
          body.copy message, headers.length

          socket.send message, 0, message.length, target_port, target_name


  socket.on 'message', (msg,rinfo) ->
    content = msg.toString 'ascii'
    if r = content.match /^SUBSCRIBE sip:(\d+)@/
      send_notification_to r[1]

  socket.bind config.voicemail.notifier_port ? 7124

  return send_notification_to
