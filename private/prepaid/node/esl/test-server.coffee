# This script expects the following variables:
#   ccnq_account       -- account to be decremented
#   target             -- where to bridge the call
#   prepaid_uri        -- URI for the prepaid API

esl = require "./esl"
util = require 'util'
querystring = require 'querystring'
cdb = require process.cwd()+'/../../../../lib/cdb'

Unique_ID = 'Unique-ID'

server = esl.createServer (@res) ->

  on_disconnect = (req,res) ->
    switch req.headers['Content-Disposition']
      when 'linger'      then res.exit()
      when 'disconnect'  then res.end()

  res.on 'esl_disconnect_notice', on_disconnect

  res.connect (req,res) ->

    # Retrieve channel parameters
    channel_data = req.body

    unique_id             = channel_data[Unique_ID]

    prepaid_account      = channel_data.variable_ccnq_account
    prepaid_destination  = channel_data.variable_target

    prepaid_cdb = cdb.new (channel_data.prepaid_uri)

    prepaid_cdb.exists (it_does) ->
      if not it_does
        util.log "Database #{channel_data.prepaid_uri} is not accessible."
        res.hangup()

      # Get account parameters
      prepaid_cdb.get prepaid_account, (r) ->
        if r.error?
          util.log "Could not find account #{account}"
          res.hangup()
        interval_duration = r.interval_duration # seconds

        check_time = (cb) ->
          account_key = "\"#{prepaid_account}\""
          options =
            uri: "/_design/prepaid/_view/current?reduce=true&group=true&key=#{querystring.escape(account_key)}"
          prepaid_cdb.req options, (r) ->
            if r.error?
              res.hangup()
            if not r? or r.value < 2
              res.hangup()
            cb?()

        record_interval = (intervals) ->
          rec =
            type: 'interval_record'
            account: @prepaid_account
            intervals: - intervals

          db.put rec, (r) ->
            if r.error?
              util.log "Error: #{r.error}"
              res.hangup()

        # Handle ANSWER event
        each_interval = () ->
          record_interval(1)
          check_time

        on_answer = (req,res) ->
          each_interval()
          setInterval each_interval, interval_duration

        res.on 'esl_event', on_answer

        on_connect = (req,res) ->

            # Check whether the call can proceed
            check_time () ->

              util.log 'bridge'
              res.execute 'bridge', prepaid_destination, (req,res) ->
                util.log "bridge says: "+util.inspect req

        # Handle the incoming connection
        res.linger (req,res) ->
          res.filter Unique_ID, unique_id, (req,res) ->
            res.event_json 'CHANNEL_ANSWER', on_connect

server.listen(7000)

