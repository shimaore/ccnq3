Server API
==========

This API can be used in conjunction with the CouchDB native API to automate complex provisioning operations.

The API uses JSON for all data transfer. The `Content-Type` header, if present, will be `application/json`.

`PUT` and `DELETE` methods are idempotent. `GET` is a safe method (produces no side-effects).

Authentication is done by submitting a `Auth:` header with each request. The username and passwords are checked against CouchDB.
This is currently a server-to-server API. Session are not supported.

A 200 OK code is sent whenever the transport was successful. However application errors might still occur.

The application was successful if the operation returned a JSON body containing the `ok` field set to `true`.
The application encountered an error if the operation returned a JSON body containing an `error` field.

Voicemail box creation
----------------------

    PUT /_ccnq3/voicemail/:number@:number_domain

* Input Body: a `vm_settings` record.
  If no `user_database` field is present in the body, a new one will be added.

* Output Body: In case of success, a JSON hash with two fields: `ok` set to `true` and `user_database` set to the name of the user database.
