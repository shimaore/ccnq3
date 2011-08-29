crud.json.js and jquery.deep from https://gist.github.com/615281 (see http://agaoglu.tumblr.com/post/1235956096/my-docform-replacement-for-crud-on-couchdb):

CRUD requires jquery.deepjson.js to work so it should be included

    <script type="text/javascript" src="js/jquery.deepjson.js"></script>

Then you can assign whatever's in crud.json to a variable or you can put 
crud.json into your evently directory and let couchapp push it to your 
application. 

Simplest way to use it is

    $.couch.app(function(app) {
      $('#form').evently(app.ddoc.evently.crud, app);
    }

If you want to put some lifecycle methods around (you usually need)

    $.couch.app(function(app) {
      $('#form').evently($.extend({}, app.ddoc.evently.crud, {
        postconstruct: function(e){
          // after form readies itself for editing
          // may show form or delete buttons here
        },
        predestroy: function(e) {
          // triggers on object deletion only
          // useful to hide form
        }
      }), app);
    }

Then you can add function to your controls like 

    $('.items a').click(function(e){
        // edit item, doc id presumed set to id attr of a
        $('#form').trigger('activate',$(this).attr('id'));
    });
    $('button.new').click(function(e){
        // ready form for a new item
        $('#form').trigger('activate', 'new');
    });
    $('button.save').click(function(e){
        // save the form
        $('#form').submit();
    });
    $('button.delete').click(function(e){
        // delete the item set in form
        $('#form').trigger('removeitem');
    });


It is possible to use $$('#form').ldoc to access the doc itself.
