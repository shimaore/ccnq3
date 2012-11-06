Server API
==========

This API can be used in conjunction with the CouchDB native API to automate complex provisioning operations.

The API uses JSON for all data transfer. The `Content-Type` header, if present, will be `application/json`.

`PUT` and `DELETE` methods are idempotent. `GET` is a safe method (produces no side-effects).

Authentication is done by submitting a `Auth:` header with each request. The username and passwords are checked against CouchDB.
This is currently a server-to-server API. Session are not supported.

The application was successful if the response status was `200`. In this case the `ok` field of the JSON response wil be set to `true`.
Otherwise the operation failed, and more information might be available in the JSON response, especially in the (optional) `error` and `when` fields.

Voicemail box creation
----------------------

    PUT /_ccnq3/voicemail/:number@:number_domain

* Input Body: a `vm_settings` record.
  If no `user_database` field is present in the body, a new one will be added.

* Output Body:
  `ok`: `true`
  `user_database`: set to the name of the user database.
