###
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
###

p_fun = (f) -> '('+f+')'

# This is installed by applications/roles (since the applications/voicemail
# module gets installed on the host running FreeSwitch, not on the manager).
ddoc =
  _id: '_design/voicemail'
  language: 'javascript'
  views: {}

module.exports = ddoc

# Note: These only list _messages_, i.e. documents with actual audio content.
ddoc.views.new_messages =
  map: p_fun (doc) ->

    if doc.type? and doc.type is 'voicemail' and doc.box? and doc.box is 'new' and doc._attachments?
      emit doc._id, null

ddoc.views.saved_messages =
  map: p_fun (doc) ->

    if doc.type? and doc.type is 'voicemail' and doc.box? and doc.box is 'saved' and doc._attachments?
      emit doc._id, null

ddoc.views.no_messages =
  map: p_fun (doc) ->

    if doc.type? and doc.type is 'voicemail' and (not doc.box? or not doc._attachments?)
      emit doc._id, null
