# This script expects the following variables:
#   ccnq_account       -- account to be decremented
#   target             -- where to bridge the call
#   prepaid_uri        -- URI for the prepaid API

esl = require "./esl"
util = require 'util'
querystring = require 'querystring'
cdb = require process.cwd()+'/../../../../lib/cdb'

esl.debug = true

Unique_ID = 'Unique-ID'

server = esl.createServer (res) ->

  res.connect (req,res) ->

    # Retrieve channel parameters
    channel_data = req.body

    unique_id             = channel_data[Unique_ID]
    util.log "Incoming call UUID = #{unique_id}"

    prepaid_account      = channel_data.variable_ccnq_account
    prepaid_destination  = channel_data.variable_target

    prepaid_cdb = cdb.new (channel_data.variable_prepaid_uri)

    # Common values
    interval_id = null
    other_leg_unique_id = null

    on_disconnect = (req,res) ->
      util.log "Receiving disconnection"
      switch req.headers['Content-Disposition']
        when 'linger'      then res.exit()
        when 'disconnect'  then res.end()



    res.on 'esl_disconnect_notice', on_disconnect



    force_disconnect = () ->
      util.log 'Hangup call'
      prepaid_cdb = null

      # Hangup leg A
      v = unique_id
      unique_id = null
      if v
        util.log 'Hangup leg A'
        res.hangup_uuid v, (req,res) ->
          util.log util.inspect req

      # Hangup leg B
      v = other_leg_unique_id
      other_leg_unique_id = null
      if v
        util.log 'Hangup leg B'
        res.hangup_uuid v, (req,res) ->
          util.log util.inspect req


    prepaid_cdb.exists (it_does) ->
      if not it_does
        util.log "Database #{channel_data.prepaid_uri} is not accessible."
        return force_disconnect()

      # Get account parameters
      prepaid_cdb.get prepaid_account, (r) ->
        if r.error
          util.log "Account #{prepaid_account} Error: #{r.error}"
          return force_disconnect()

        interval_duration = r.interval_duration # seconds
        util.log "Account #{prepaid_account} interval duration is #{interval_duration} seconds."

        check_time = (cb) ->
          util.log "Checking account #{prepaid_account}."
          account_key = "\"#{prepaid_account}\""
          options =
            uri: "/_design/prepaid/_view/current?reduce=true&group=true&key=#{querystring.escape(account_key)}"
          prepaid_cdb.req options, (r) ->
            if r.error
              util.log "Error: #{r.error}"
              return force_disconnect()

            intervals_remaining = r?.rows?[0]?.value

            if intervals_remaining? and intervals_remaining > 1
              util.log "Account #{prepaid_account} has #{intervals_remaining} intervals left."
              return cb?()

            util.log "Account #{prepaid_account} is exhausted."
            return force_disconnect()

        # During call progress, check every ten seconds whether
        # the account is exhausted.
        interval_id = setInterval check_time, 10*1000

        record_interval = (intervals,cb) ->
          util.log "Recording #{intervals} intervals for account #{prepaid_account}."
          rec =
            type: 'interval_record'
            account: prepaid_account
            intervals: - intervals

          prepaid_cdb.put rec, (r) ->
            if r.error
              util.log "Error: #{r.error}"
              return force_disconnect()

            util.log "Recorded #{intervals} intervals for account #{prepaid_account}."
            cb?()

        each_interval = (cb) ->
          record_interval 1, () ->
            check_time(cb)

        # Handle ANSWER event
        on_answer = (req,res) ->
          util.log "Call was answered"

          # Clear the ringback timer
          clearInterval interval_id
          interval_id = null

          # First interval for the connected call
          each_interval()

          # Set the in-call timer
          interval_id = setInterval each_interval, interval_duration*1000

          util.log "Call answer processed."

        res.on 'esl_event', (req,res) ->
          switch req.body['Event-Name']

            when 'CHANNEL_ANSWER'
              on_answer(req,res)

            when 'CHANNEL_BRIDGE'
              other_leg_unique_id = req.body['Other-Leg-Unique-ID']
              res.filter Unique_ID, other_leg_unique_id

            when 'CHANNEL_HANGUP_COMPLETE'
              util.log 'Channel hangup complete'
              clearInterval interval_id
              interval_id = null

            else
              util.log "Unhandled event #{req.body['Event-Name']}"

        on_connect = (req,res) ->

            # Check whether the call can proceed
            check_time () ->

              util.log 'Bridging call'
              res.execute 'bridge', prepaid_destination, (req,res) ->
                util.log "Call bridged"

        # Handle the incoming connection
        res.linger (req,res) ->
          res.filter Unique_ID, unique_id, (req,res) ->
            res.event_json 'ALL', on_connect

server.listen(7000)

