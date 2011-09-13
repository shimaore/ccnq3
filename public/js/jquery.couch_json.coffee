#
# Prerequisites: jquery.couchdb, jquery.deepjson
#

crud2 = ($) ->
  $.fn.set_couchdb_name = (name) ->
    $$(@).cdb = new $.couch.db name
    return @

  $.fn.load_couchdb_item = (id,cb) ->
    # load data from couchdb and display it in the form
    # @reset()
    that = @
    $$(@).cdb.openDoc id,
        error: ->
          $$(that).ldoc = {_id:id}
          # that.reset()
        success: (doc) ->
          $$(that).ldoc = doc
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
    $$(@).ldoc = doc

  $.fn.remove_couchdb_item = (cb) ->
    # Delete doc from couchdb
    if confirm("Are you sure?")
      $$(@).cdb.removeDoc($$(@).ldoc)
      cb?()

  $.fn.save_couchdb_item = (cb) ->
    # encode the data in form and save it to couchdb
    reg = $.extend({},$$(@).ldoc, $(@).toDeepJson())
    that = @
    $$(@).cdb.saveDoc reg,
        success: (res) ->
          reg._id = res.id
          reg._rev = res.rev
          $$(that).ldoc = reg
          cb?(reg)
    return false

crud2(jQuery)
