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
    $.compile_template = function(template) {
      return CoffeeKup.compile(template, {
        hardcode: coffeekup_helpers
      });
    };
    $.fn.auto_add = function() {
      var add_line, table;
      table = this;
      $('.template', table).hide().append('<td><div class="del ui-icon ui-icon-closethick">remove</div></td>');
      add_line = function() {
        var rank, row;
        rank = 0;
        $('tr.data', table).each(function() {
          return rank++;
        });
        row = $('.template', table).clone().removeClass('template').addClass('data').show().appendTo(table);
        $('input,select', row).each(function() {
          return $(this).attr('name', function(index, name) {
            return name.replace('*', rank);
          });
        });
        $('.del', row).click(function() {
          row.remove();
          return false;
        });
      };
      $('tr:first', table).append('<th><div class="add ui-icon ui-icon-plusthick">add line</div></th>');
      $('.add', table).click(function() {
        return add_line();
      });
      return add_line();
    };
  })(jQuery);
}).call(this);
