#
# Prerequisites: jquery.couchdb, jquery.deepjson
#

crud2 = ($) ->
  $.fn.set_couchdb_name = (name) ->
    $(@).data 'cdb', new $.couch.db name
    return @

  $.fn.load_couchdb_item = (id,cb) ->
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

  $.fn.new_couchdb_item = ->
    # activate form for new items
    # @reset()
    doc = {}
    $(@).data 'ldoc', doc

  $.fn.remove_couchdb_item = (cb) ->
    # Delete doc from couchdb
    if confirm("Are you sure?")
      $(@).data('cdb').removeDoc($(@).data('ldoc'))
      cb?()

  $.fn.save_couchdb_item = (cb) ->
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

crud2(jQuery)
