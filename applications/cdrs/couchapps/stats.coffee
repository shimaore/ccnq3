p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/stats'
  filters: {}
  language: 'javascript'
  views:
    # Report hourly statistics (count=number of call attempts)
    hourly_profile:
      map: p_fun (doc) ->
        return unless doc.variables?
        hour = doc.variables.start_stamp.substr 0, 13
        direction = doc.variables.ccnq_direction
        profile = doc.variables.ccnq_profile
        cause = doc.variables.proto_specific_hangup_cause ? doc.variables.last_bridge_proto_specific_hangup_cause
        emit [hour,direction,profile,cause], doc.mbillsec ? 0
        return
      reduce: '_stats'
    account_monitor:
      map: p_fun (doc) ->
        return unless doc.variables?
        account = doc.ccnq_account
        direction = doc.variables.ccnq_direction
        hour = doc.variables.start_stamp.substr 0, 13
        emit [hour,direction,account], doc.mbillsec ? 0
        return
      reduce: p_fun (key,values,rereduce) ->
        result =
          attempts: 0
          success: 0
          duration: 0
        if not rereduce
          for v in values
            result.attempts += 1
            result.success += 1 if v > 0
            result.duration += v
        else
          for v in values
            result.attempts += v.attempts
            result.success += v.success
            result.duration += v.duration

module.exports = ddoc
