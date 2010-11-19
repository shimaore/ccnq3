(function($) {
  $.fn.deserialize = function (data) {
    // "this" refers to the jQuery object
    this.find('input,textarea,select').each( function() {
      // "this" refers to the DOM element
      if(this.type && (this.type == 'reset' || this.type == 'submit'))
        return;
      if(this.name && data[this.name]) $(this).val(data[this.name])
      else
      if(this.id   && data[this.id]  ) $(this).val(data[this.id])
      else
      $(this).val('')
    });
    return this;
  };
})(jQuery);
