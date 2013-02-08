Data server
-----------

CouchDB server must run:
    applications/couch_daemon

CouchDB server may run (these do not start network services, only configure database, do compaction, etc.):
    applications/cdrs
    applications/locations
    applications/logging
    applications/provisioning

It doesn't have to run `applications/host`, unless desired.
