/* Support for CouchDB Continuous Changes API.
   Copyright (c) 2011 Stéphane Alnet
   Released under the Affero GPL3 license or above. */

/* TODO: implement retries on failure or timeout */

(function($) {
  $.fn.cdbcc = function (url,cb) {
    var buffer = '';
    $.ajax({
      url:url,
      cache:false,
      async:true,
      dataType: 'application/json',
      'global': false,
      dataFilter: function(data,type) {
        buffer += data;
        var d = buffer.split("\n");
        while(d.length > 1) {
          cb(d.shift());
        }
        buffer = d[0];
      },
    })
  };
})(jQuery);
