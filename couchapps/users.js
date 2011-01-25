/*
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
*/

// Install:
//   couchapp push users.js http://127.0.0.1:5984/_users

var couchapp = require('couchapp');
var path     = require('path');

ddoc = {
    _id: '_design/app'
  , views: {}
  , lists: {} // http://guide.couchdb.org/draft/transforming.html
  , shows: {} // http://guide.couchdb.org/draft/show.html
  , filters: {} // used by _changes
  , rewrites: {} // http://blog.couchone.com/post/443028592/whats-new-in-apache-couchdb-0-11-part-one-nice-urls
}

module.exports = ddoc;

ddoc.filters.send_confirmation = function(doc,req) {
  return doc.status == 'send_confirmation' ? true : false;
}

ddoc.validate_doc_update = function (newDoc, oldDoc, userCtx) {

  if(doc.status !== 'confirmed') {
    for (var i in doc.roles) {
      if( doc.roles[i].match('^account:') ) {
        throw({forbidden : "Only registered users might be granted account access."});
      }
    }
  }


}

// Attachments are loaded from portal/*
// couchapp.loadAttachments(ddoc, path.join(__dirname, 'users'));
