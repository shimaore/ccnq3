(function() {
  /*
  Deserialize and update a Javascript record into an HTML form.
  Copyright (c) 2010 Stephane Alnet
  Released under the Affero GPL3 license or above.
  */  (function($) {
    var change_json_value, get_json_value;
    get_json_value = function(data, name) {
      var index, match, part, rest, _i;
      if (!(data != null)) {
        return data;
      }
      if (!(name != null) || name === '') {
        return data;
      }
      if (match = name.match(/^\[(\d+)\](.*)$/)) {
        _i = match[0], part = match[1], rest = match[2];
        index = parseInt(part) - 1;
        return arguments.callee(data[index], rest);
      }
      if (match = name.match(/^\.?(\w+)(.*)$/)) {
        _i = match[0], part = match[1], rest = match[2];
        return arguments.callee(data[part], rest);
      }
      throw "Could not parse name " + name;
    };
    change_json_value = function(data, name, value) {
      var index, match, part, rest, _i;
      if (!(name != null) || name === '') {
        data = value;
        return data;
      }
      if (match = name.match(/^\[(\d+)\](.*)$/)) {
        _i = match[0], part = match[1], rest = match[2];
                if (data != null) {
          data;
        } else {
          data = [];
        };
        index = parseInt(part) - 1;
        data[index] = arguments.callee(data[index], rest, value);
        return data;
      }
      if (match = name.match(/^\.?(\w+)(.*)$/)) {
        _i = match[0], part = match[1], rest = match[2];
                if (data != null) {
          data;
        } else {
          data = {};
        };
        data[part] = arguments.callee(data[part], rest, value);
        return data;
      }
      throw "Could not parse name " + name;
    };
    $.fn.form_from_json = function(data) {
      this.find('input,textarea,select').each(function() {
        if (this.type && (this.type === 'reset' || this.type === 'submit')) {
          return;
        }
        if (this.name && this.name === '_method') {
          return;
        }
        if (this.name && data[this.name]) {
          return $(this).val(get_json_value(data, this.name));
        }
        if (this.id && data[this.id]) {
          return $(this).val(get_json_value(data, this.id));
        }
        return $(this).val('');
      });
      return this;
    };
    return $.fn.form_update_json = function(data) {
      this.find('input,textarea,select').each(function() {
        if (this.type && (this.type === 'reset' || this.type === 'submit')) {
          return;
        }
        if (this.name && this.name === '_method') {
          return;
        }
        if (this.name && data[this.name]) {
          return change_json_value(data, this.name, $(this).val());
        }
        if (this.id && data[this.id]) {
          return change_json_value(data, this.id, $(this).val());
        }
      });
      return this;
    };
  });
  jQuery;
}).call(this);
