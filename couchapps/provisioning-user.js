/*
(c) 2011 Stephane Alnet
Released under the Affero GPL3 license or above
*/


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

// http://wiki.apache.org/couchdb/Document_Update_Validation
ddoc.validate_doc_update = function (newDoc, oldDoc, userCtx) {

  // Typically the "writer" role will only be given to the replication
  // and dispatcher processes.
  if (userCtx.roles.indexOf('writer') === -1) {
    throw({
      forbidden: 'Database cannot be updated.'
    });
  }

  // Other checks here (could be a duplicate of the provisioning-global checks, used to validate replication).

}


// Attachments are loaded from portal/*
couchapp.loadAttachments(ddoc, path.join(__dirname, 'provisioning'));
