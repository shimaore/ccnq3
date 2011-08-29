(function( $ ){
  $.fn.toDeepJson = function() {
    function parse(val){
      if (val == ""){ return null; }
      if (val == "true"){ return true; }
      if (val == "false"){ return false; }
      if (val == String(parseInt(val))){ return parseInt(val); }
      if (val == String(parseFloat(val))){ return parseFloat(val); }
      return val;      
    }
    function toNestedObject(obj, arr){
      var key = arr.shift();
      if (arr.length > 0) {
        obj[key] = toNestedObject(obj[key] || {}, arr);
        return obj;
      }
      return key;
    }
    if (this.length == 1){
      return $.makeArray(this[0].elements)
      .filter(function(e){
          return e.name != "" && (e.type == 'radio' ? e.checked : true);
      })
      .map(function(e){
          var names = e.name.split('.');
          if (e.type == 'checkbox') {
            e.value = e.checked;
          }
          names.push(parse(e.value));
          return names;
      })
      .reduce(toNestedObject, {});
    } else {
      throw({error:"Can work on a single form only"})
    }
  };

  $.flatten = function (obj){
    var ret = {}
    for (var key in obj){
      if (typeof obj[key] == 'object'){
        var fobj = $.flatten(obj[key]);
        for (var extkey in fobj){
          ret[key+"."+extkey] = fobj[extkey];
        }
      } else {
        ret[key] = String(obj[key]);
      }
    }
    return ret;
  }
  
})( jQuery );

