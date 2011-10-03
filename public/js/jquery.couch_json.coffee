#
# Prerequisites: jquery.couchdb, jquery.deepjson
#

crud2 = ($) ->
  $.fn.couch_name = (name) ->
    $(@).data 'cdb', $.couch.db name
    return @

  $.fn.couch_load = (id,cb) ->
    # load data from couchdb and display it in the form
    # @reset()
    that = @
    $(@).data('cdb').openDoc id,
        error: ->
          $(that).data 'ldoc', {_id:id}
          # that.reset()
        success: (doc) ->
          $(that).data 'ldoc', doc
          fdoc = $.flatten(doc)
          for name in fdoc
            do (name) ->
              $(':input[name='+name+']', that).val(fdoc[name])
              $(':checkbox[name='+name+']', that).attr('checked',fdoc[name])
          cb?(doc)

  $.fn.couch_new = ->
    # activate form for new items
    # @reset()
    doc = {}
    $(@).data 'ldoc', doc

  $.fn.couch_remove = (cb) ->
    # Delete doc from couchdb
    if confirm("Are you sure?")
      $(@).data('cdb').removeDoc($(@).data('ldoc'))
      cb?()

  $.fn.couch_save = (cb) ->
    # encode the data in form and save it to couchdb
    reg = $.extend({},$(@).data('ldoc'), $(@).toDeepJson())
    that = @
    $(@).data('cdb').saveDoc reg,
        success: (res) ->
          reg._id = res.id
          reg._rev = res.rev
          $(that).data 'ldoc', reg
          cb?(reg)
    return false

  return

crud2(jQuery)
