p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/replicate'
  filters: {}

module.exports = ddoc

ddoc.validate_doc_update = p_fun (newDoc, oldDoc, userCtx) ->

  user_is = (role) ->
    userCtx.roles?.indexOf(role) >= 0

  if not user_is('cdrs_writer') and not user_is('_admin') and not user_is('host')
    throw forbidden:"Not authorized to write in this database, roles = #{userCtx.roles?.join(",")}."
