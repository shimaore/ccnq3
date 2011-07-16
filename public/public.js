(function() {
  /*
  (c) 2011 Stephane Alnet
  Released under the Affero GPL3 license or above
  */  var couchapp, ddoc, path;
  couchapp = require('couchapp');
  path = require('path');
  ddoc = {
    _id: '_design/public',
    views: {},
    lists: {},
    shows: {},
    filters: {},
    rewrites: {}
  };
  module.exports = ddoc;
  ddoc.filters.hostname = function(doc, req) {
    return doc.type === 'host' && doc.host === req.query.hostname;
  };
  couchapp.loadAttachments(ddoc, path.join(__dirname));
}).call(this);
