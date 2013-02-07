About
=====

This application provides the *Extended API* embedded in the central CouchDB
database.

It is meant to provide API (REST/JSON) calls. In order to keep performance and
stability at reasonable levels, it SHOULD NOT serve static content (web
pages, etc.); these should be part of your management website, not part of
CCNQ3.

How to enable the service
=========================

Add `applications/couch_daemon` to the `applications` array for the host
running CouchDB. This is normally automatically done for you on the _manager_
host.

Configuration Details
=====================

This service is intended to be available through CouchDB, using CouchDB's
`couch_http_proxy`:

    [httpd_global_handlers]
    _ccnq3 = {couch_httpd_proxy, handle_proxy_req, <<"http://127.0.0.1:35984/_ccnq3">>}

Note that the mapping is left under `/_ccnq3` so that you may use other proxies
(which may not be able to do URL rewriting).

This configuration is installed automatically by the Debian `ccnq3-couchdb`
package; the template is found in `bin/manager.ini`.

Extending the API
=================

Extending the API is done by providing a [ZappaJS](https://github.com/zappajs/zappajs)
`include` module in `${SRC}/applications/couch_daemon/zappa/include` (you can obtain
the proper value for `${SRC}` by running `ccnq3 src`). Your script should check for
proper authentication before it starts:

    @get '/_ccnq3/example', ->
      if not @rew.user?
        return @failure error:"Not authorized"

Inside the script, you can access the username and password for CouchDB as

      @req.user # CouchDB username provided by the client
      @req.pass # CouchDB password provided by the client

This allows you to access the database using the same permissions as the client,
if that is what you want. Otherwise your script might also be used to provide
permissions escalation. Just use responsibly.
