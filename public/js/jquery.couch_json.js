(function() {
  var crud2;
  crud2 = function($) {
    $.fn.set_couchdb_name = function(name) {
      $$(this).cdb = new $.couch.db(name);
      return this;
    };
    $.fn.load_couchdb_item = function(id, cb) {
      var that;
      that = this;
      return $$(this).cdb.openDoc(id, {
        error: function() {
          return $$(that).ldoc = {
            _id: id
          };
        },
        success: function(doc) {
          var fdoc, name, _fn, _i, _len;
          $$(that).ldoc = doc;
          fdoc = $.flatten(doc);
          _fn = function(name) {
            $(':input[name=' + name + ']', that).val(fdoc[name]);
            return $(':checkbox[name=' + name + ']', that).attr('checked', fdoc[name]);
          };
          for (_i = 0, _len = fdoc.length; _i < _len; _i++) {
            name = fdoc[_i];
            _fn(name);
          }
          return typeof cb === "function" ? cb(doc) : void 0;
        }
      });
    };
    $.fn.new_couchdb_item = function() {
      var doc;
      doc = {};
      return $$(this).ldoc = doc;
    };
    $.fn.remove_couchdb_item = function(cb) {
      if (confirm("Are you sure?")) {
        $$(this).cdb.removeDoc($$(this).ldoc);
        return typeof cb === "function" ? cb() : void 0;
      }
    };
    return $.fn.save_couchdb_item = function(cb) {
      var reg, that;
      reg = $.extend({}, $$(this).ldoc, $(this).toDeepJson());
      that = this;
      $$(this).cdb.saveDoc(reg, {
        success: function(res) {
          reg._id = res.id;
          reg._rev = res.rev;
          $$(that).ldoc = reg;
          return typeof cb === "function" ? cb(reg) : void 0;
        }
      });
      return false;
    };
  };
  crud2(jQuery);
}).call(this);
