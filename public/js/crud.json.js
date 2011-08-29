{
  activate: function(e, id) {
    // activate the form, enabling edits
    if (id == "new"){
      $(this).trigger('newitem');
    } else {
      $(this).trigger('loaditem', id);
    }
  },
  loaditem: function(e, id) {
    // load data from couchdb and display it in the form
    this.reset();
    var that = this;
    $$(this).app.db.openDoc(id, {
        error: function() {
          $$(that).ldoc = {_id:id}
          that.reset();
        },
        success: function(doc){
          $$(that).ldoc = doc;
          var fdoc = $.flatten(doc);
          for (var name in fdoc){
            $(':input[name='+name+']', that).val(fdoc[name]);
            $(':checkbox[name='+name+']', that).attr('checked',fdoc[name]);
          }
          $(that).trigger('postconstruct');
        }
    })
  },
  newitem: function(e) {
    // activate form for new items
    this.reset();
    $$(this).ldoc = {};
    $(this).trigger('postconstruct');
  },
  removeitem: function(e){
    // Self-explanatory, delete doc from couchdb
    if (confirm("Are you sure?")){
      $$(this).app.db.removeDoc($$(this).ldoc);
      $(this).trigger('predestroy');
    }
  },
  submit: function(e){
    // encode the data in form and save it to couchdb
    var reg = $.extend({},$$(this).ldoc, $(this).toDeepJson());
    var that = this;
    $$(this).app.db.saveDoc(reg,{
        success: function(res){
          reg._id = res.id;
          reg._rev = res.rev;
          $$(that).ldoc = reg;
          $(that).trigger('postconstruct');
        }
    });
    return false;
  }
} 
