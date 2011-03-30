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
    util.log "Incoming call UUID = #{unique_id}"

    prepaid_account      = channel_data.variable_ccnq_account
    prepaid_destination  = channel_data.variable_target

    prepaid_cdb = cdb.new (channel_data.variable_prepaid_uri)

    prepaid_cdb.exists (it_does) ->
      if not it_does
        util.log "Database #{channel_data.prepaid_uri} is not accessible."
        return res.end()

      # Get account parameters
      prepaid_cdb.get prepaid_account, (r) ->
        if r.error?
          util.log "Could not find account #{account}"
          return res.end()

        interval_duration = r.interval_duration # seconds
        util.log "Account #{prepaid_account} interval duration is #{interval_duration} seconds."

        check_time = (cb) ->
          util.log "Checking account #{prepaid_account}."
          account_key = "\"#{prepaid_account}\""
          options =
            uri: "/_design/prepaid/_view/current?reduce=true&group=true&key=#{querystring.escape(account_key)}"
          prepaid_cdb.req options, (r) ->
            if r.error?
              return res.end()

            if r.value < 2
              util.log "Account #{prepaid_account} is exhausted."
              return res.end()

            util.log "Account #{prepaid_account} has #{r.value} intervals left."
            cb?()

        record_interval = (intervals,cb) ->
          util.log "Recording #{intervals} intervals for account #{prepaid_account}."
          rec =
            type: 'interval_record'
            account: prepaid_account
            intervals: - intervals

          prepaid_cdb.put rec, (r) ->
            if r.error?
              util.log "Error: #{r.error}"
              return res.end()

            util.log "Recorded #{intervals} intervals for account #{prepaid_account}."
            cb?()

        # Handle ANSWER event
        each_interval = (cb) ->
          record_interval 1, () ->
            check_time(cb)

        on_answer = (req,res) ->
          util.log "Call was answered"
          each_interval()
          setInterval each_interval, interval_duration*1000

        res.on 'esl_event', on_answer

        on_connect = (req,res) ->

            # Check whether the call can proceed
            check_time () ->

              util.log 'Bridging call'
              res.execute 'bridge', prepaid_destination, (req,res) ->
                util.log "Call bridged"

        # Handle the incoming connection
        # res.linger (req,res) ->
        res.filter Unique_ID, unique_id, (req,res) ->
          res.event_json 'CHANNEL_ANSWER', on_connect

server.listen(7000)

