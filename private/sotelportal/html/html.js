(function() {
  /*
  (c) 2011 Stephane Alnet
  Released under the Affero GPL3 license or above
  */  var couchapp, ddoc, path;
  couchapp = require('couchapp');
  path = require('path');
  ddoc = {
    _id: '_design/html',
    views: {},
    lists: {},
    shows: {},
    filters: {},
    rewrites: []
  };
  module.exports = ddoc;
  ddoc.rewrites.push({
    from: '/',
    to: 'index.html'
  });
  ddoc.rewrites.push({
    from: '/public/*',
    to: '../public/*'
  });
  ddoc.rewrites.push({
    from: '/*',
    to: '*'
  });
  couchapp.loadAttachments(ddoc, path.join(__dirname));
}).call(this);
