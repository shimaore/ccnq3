###
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

ddoc =
  _id: '_design/voicemail-store'
  views: {}

module.exports = ddoc

# Information about user databases
ddoc.views.userdb =
  map: p_fun (doc) ->
    if doc.user_database?
      emit doc.user_database, doc.name
