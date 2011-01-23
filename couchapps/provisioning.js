/*
(c) 2010 Stephane Alnet
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

ddoc.shows.user = function(doc,req) {
  var module = 'provisioning';

  var userCtx = req.userCtx;
  for (var i in userCtx.roles) {
    var prefix = userCtx.roles[i];

    if(!doc.account // A document that is not constrained by an account is visible by everyone.
      || (module+':'+doc.account).substring(0,prefix.length) === prefix) {
      return {
        body: JSON.stringify(doc),
        headers: {
          "Content-Type" : "application/json",
        }
      };
    }
  }

  // Otherwise return an empty document.
  return {
    body: '{}',
    headers: {
      "Content-Type" : "application/json",
    }
  };
}

ddoc.lists.user = function(head, req) {
  var row;
  while (row = getRow()) {
    send(JSON.stringify(row))
  }
}


/*
# http://wiki.apache.org/couchdb/Document_Update_Validation
ddoc.validate_doc_update = function (newDoc, oldDoc, userCtx) {

  function require(field, message) {
    message = message || "Document must have a " + field;
    if (!newDoc[field]) throw({forbidden : message});
  };
  function unchanged(field) {
    if (oldDoc && toJSON(oldDoc[field]) != toJSON(newDoc[field]))
      throw({forbidden : "Field can't be changed: " + field});
  }


        if (newDoc._deleted === true) {
            // allow deletes by admins and matching users
            // without checking the other fields
            if ((userCtx.roles.indexOf('_admin') !== -1) ||
                (userCtx.name == oldDoc.name)) {
                return;
            } else {
                throw({forbidden: 'Only admins may delete other user docs.'});
            }
        }

        if ((oldDoc && oldDoc.type !== 'user') || newDoc.type !== 'user') {
            throw({forbidden : 'doc.type must be user'});
        } // we only allow user docs for now

        if (!newDoc.name) {
            throw({forbidden: 'doc.name is required'});
        }

        if (!(newDoc.roles && (typeof newDoc.roles.length !== 'undefined'))) {
            throw({forbidden: 'doc.roles must be an array'});
        }

        if (newDoc._id !== ('org.couchdb.user:' + newDoc.name)) {
            throw({
                forbidden: 'Doc ID must be of the form org.couchdb.user:name'
            });
        }

        if (oldDoc) { // validate all updates
            if (oldDoc.name !== newDoc.name) {
                throw({forbidden: 'Usernames can not be changed.'});
            }
        }

        if (newDoc.password_sha && !newDoc.salt) {
            throw({
                forbidden: 'Users with password_sha must have a salt.' +
                    'See /_utils/script/couch.js for example code.'
            });
        }

        if (userCtx.roles.indexOf('_admin') === -1) {
            if (oldDoc) { // validate non-admin updates
                if (userCtx.name !== newDoc.name) {
                    throw({
                        forbidden: 'You may only update your own user document.'
                    });
                }
                // validate role updates
                var oldRoles = oldDoc.roles.sort();
                var newRoles = newDoc.roles.sort();

                if (oldRoles.length !== newRoles.length) {
                    throw({forbidden: 'Only _admin may edit roles'});
                }

                for (var i = 0; i < oldRoles.length; i++) {
                    if (oldRoles[i] !== newRoles[i]) {
                        throw({forbidden: 'Only _admin may edit roles'});
                    }
                }
            } else if (newDoc.roles.length > 0) {
                throw({forbidden: 'Only _admin may set roles'});
            }
        }

        // no system roles in users db
        for (var i = 0; i < newDoc.roles.length; i++) {
            if (newDoc.roles[i][0] === '_') {
                throw({
                    forbidden:
                    'No system roles (starting with underscore) in users db.'
                });
            }
        }

        // no system names as names
        if (newDoc.name[0] === '_') {
            throw({forbidden: 'Username may not start with underscore.'});
        }
    }

}
*/

// Attachments are loaded from portal/*
couchapp.loadAttachments(ddoc, path.join(__dirname, 'provisioning'));
