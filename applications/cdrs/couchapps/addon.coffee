p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/addon'
  filters: {}
  language: 'javascript'
  views:
    cdr_by_number:
      map: p_fun (doc) ->
        return unless doc.variables?
        if doc.variables.ccnq_from_e164?
          emit [
            doc.variables.ccnq_from_e164
            doc.variables.start_stamp
          ]
        if doc.variables.ccnq_to_e164?
          emit [
            doc.variables.ccnq_to_e164
            doc.variables.start_stamp
          ]
        return

module.exports = ddoc
