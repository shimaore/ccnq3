/*
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
*/


var couchapp = require('couchapp');
var path     = require('path');

ddoc = {
    _id: '_design/prepaid'
  , views: {}
  , lists: {} // http://guide.couchdb.org/draft/transforming.html
  , shows: {} // http://guide.couchdb.org/draft/show.html
  , filters: {} // used by _changes
  , rewrites: {} // http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
};

module.exports = ddoc;

ddoc.views.current = {
  map: function (doc) {
    if(doc.intervals) {
      emit(doc.account,doc.intervals)
    }
  },
  reduce: "_sum"
};

// Attachments are loaded from prepaid/*
couchapp.loadAttachments(ddoc, path.join(__dirname, 'prepaid'));
