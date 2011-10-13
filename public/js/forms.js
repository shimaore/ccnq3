(function() {
  (function(jQuery) {
    var $, coffeekup_helpers;
    $ = jQuery;
    $.fn.disable = function() {
      return $(this).attr('disabled', 'true');
    };
    $.fn.enable = function() {
      return $(this).removeAttr('disabled');
    };
    $.getScript('/public/js/coffeekup.js');
    coffeekup_helpers = {
      checkbox: function(attrs) {
        var _ref, _ref2;
        attrs.type = 'checkbox';
        attrs.name = attrs.id;
        if ((_ref = attrs.value) == null) {
          attrs.value = 'true';
        }
        if ((_ref2 = attrs["class"]) == null) {
          attrs["class"] = 'normal';
        }
        return label({
          "for": attrs.name,
          "class": attrs["class"]
        }, function() {
          span(attrs.title);
          return input(attrs);
        });
      },
      textbox: function(attrs) {
        var _ref;
        attrs.type = 'text';
        attrs.name = attrs.id;
        if ((_ref = attrs["class"]) == null) {
          attrs["class"] = 'normal';
        }
        return label({
          "for": attrs.name,
          "class": attrs["class"]
        }, function() {
          span(attrs.title);
          return input(attrs);
        });
      },
      text_area: function(attrs) {
        var _ref, _ref2, _ref3;
        attrs.name = attrs.id;
        if ((_ref = attrs.rows) == null) {
          attrs.rows = 3;
        }
        if ((_ref2 = attrs.cols) == null) {
          attrs.cols = 3;
        }
        if ((_ref3 = attrs["class"]) == null) {
          attrs["class"] = 'normal';
        }
        return label({
          "for": attrs.name,
          "class": attrs["class"]
        }, function() {
          span(attrs.title);
          return textarea(attrs);
        });
      }
    };
    return $.compile_template = function(template) {
      return CoffeeKup.compile(template, {
        hardcode: coffeekup_helpers
      });
    };
  })(jQuery);
}).call(this);
