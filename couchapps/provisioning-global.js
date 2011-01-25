/*
(c) 2010 Stephane Alnet
Released under the Affero GPL3 license or above
*/

// Install:
//  couchapp push provisioning.js http://127.0.0.1:5984/provisioning

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

  if(newDoc._id === "_design/userapp") {
    throw({forbidden:'The user application should not be replicated here.'});
  }

  function required(field, message) {
    message = message || "Document must have a " + field;
    if (!newDoc[field]) throw({forbidden : message});
  }

  function unchanged(field) {
    if (oldDoc && toJSON(oldDoc[field]) != toJSON(newDoc[field]))
      throw({forbidden : "Field can't be changed: " + field});
  }

  function user_match(account,message) {
    for (var i in userCtx.roles) {
      var prefix = userCtx.roles[i];
      if( ("account:"+account).substring(0,prefix.length) === prefix ) return;
    }
    throw({forbidden : message||"No access to this account"});
  }

  function user_is(role) {
    return userCtx.roles.indexOf(role) >= 0;
  }

  // Only admins or confirmed users may modify documents.
  // (Newly registered users may not.)
  if ( !user_is('_admin') && !user_is('confirmed') ) {
    throw({forbidden : "Not a confirmed user."});
  }

  // Handle delete documents.
  if (newDoc._deleted === true) {

    if (!user_is('_admin')) {
      throw({forbidden: 'Only admins may delete documents.'});
    }

    if(oldDoc.do_not_delete) {
      throw({forbidden: 'Document is tagged as do_not_delete.'});
    }

    return;
  } else {
    // Document was not deleted, any tests here?
  }

  required("account");

  required("type");
  unchanged("type");
  if( type !== "number" && type !== "endpoint" && type != "location" ) {
    throw({forbidden: 'Invalid type.'});
  }

  required(newDoc.type);
  unchanged(newDoc.type);
  if(newDoc._id !== newDoc.type+":"+newDoc[newDoc.type]) {
    throw({forbidden: 'Document ID must be type:key.'});
  }

  // User should have access to the account to be able to create or update document inside it.
  user_match(newDoc.account);

  // Validate updates
  if( oldDoc ) {
    if( newDoc.account !== oldDoc.account ) {
      user_match(oldDoc.account,"Attempt to change document account failed.");
    }
    // Other updates
  }

  // Validate create
  if( !oldDoc ) {
    if(newDoc.type === "number") {
      if (!user_is('_admin')) {
        throw({forbidden: 'Only admins may create new numbers.'});
      }
    }
  }

  // Validate fields
  if(newDoc.type == "endpoint") {
    if( !newDoc.ip && !newDoc.username ) {
      throw({forbidden: 'IP or Username must be provided.'});
    }
    if( newDoc.ip && newDoc.ip.match(/^(192\.168\.|172\.(1[6-9]|2[0-9]|3[12])|10\.|fe80:)/) ) {
      throw({forbidden: 'Invalid IP address.'});
    }
    if( newDoc.username ) {
      required("password");
    }
  }

}

ddoc.filters.user_replication = function(doc, req) {
  # Prefix is required
  if(!req.prefix) {
    return false;
  }
  # Only replicate documents, do not replicate _design objects (for example).
  if(!doc.account) {
    return false;
  }
  # Replicate documents for which the account is a subset of the prefix.
  if(doc.account.substr(0,req.prefix.length) === req.prefix) {
    return true;
  }
  # Do not otherwise replicate
  return false;
}

// Attachments are loaded from portal/*
couchapp.loadAttachments(ddoc, path.join(__dirname, 'provisioning'));
