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
        cause = doc.variables.proto_specific_hangup_cause
        emit [hour,direction,profile,cause], doc.mbillsec
        return
      reduce: '_stats'

module.exports = ddoc
