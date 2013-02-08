CouchDB API
===========

The native CouchDB API is available to a server-side or client-side application.

Extended API
============

Integrated with CouchDB is a set of ccnq3-specific APIs accessible using the same URI as the CouchDB instance on the manager host.
Make sure `applications/couchdb_daemon` is enabled for these APIs to be available via CouchDB.

This API can be used in conjunction with the CouchDB native API to automate complex provisioning operations.

The API uses JSON for all data transfer. The `Content-Type` header, if present, will be `application/json`.

`PUT` and `DELETE` methods are idempotent. `GET` is a safe method (produces no side-effects).

The API calls are authentified using the Basic Authentication header and regular CouchDB username and password (the content of the authentication header is used by the APIs to authenticate their calls to CouchDB).

This is a server-to-server API. CouchDB sessions are not supported.

The application was successful if the response status was `200`. In this case the `ok` field of the JSON response wil be set to `true`.
Otherwise the operation failed, and more information might be available in the JSON response, especially in the (optional) `error` and `when` fields.

Test
----

`GET /_ccnq3`

Voicemail box creation
----------------------

    PUT /_ccnq3/voicemail/:number@:number_domain

* Input Body: a `vm_settings` record.
  If no `user_database` field is present in the record for the local number, a new one will be added.

* Output Body:
  `ok`: `true`
  `user_database`: set to the name of the user database.

This operation will:
* locate the local number's record
* if a `user_database` field is present, it will be used; otherwise a new one will be assigned
* the database will be created
* if any user is using this database, they will be authorized for read/write
* a `voicemail_settings` record is created inside the databse, with its content set or updated to the fields provided in the body of the `PUT` request.

Return a JSON content with a `user_database` field on success.

Note: `applications/voicemail-store` must be installed for the user database to be properly initialized.

Trace request
-------------

    PUT /_ccnq3/traces

Publish a trace request in the AMQP bus; the body of the HTTP request will be used as the AMQP request body.
