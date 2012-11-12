Conventions for usernames in CouchDB
====================================

For people, use people's actual email addresses.
For processes, use process_name@server_name.
  (For example: freeswitch@prepaid.example.net, replicator@cdb1.example.net.)
Reserve shortnames (no "@" sign) for admin accounts.

Conventions for CouchDB access
==============================

View as a single system (using potential scaling arch., replication).
(See BigCouch.)

Common definitions:

- Source databases are global databases containing the entire system information.
  Examples: "provisioning", "billing", "_users", "usercode"

  They are only accessible by system accounts.

  The _users database is maintained by the "portal" application, which takes care of
  registering users, etc.

  The main provisioning database is never accessed directly, it is always replicated
  (to/from user databases, or to servers copies).

  The main billing database is accessed by system scripts that rate CDRs, provide
  summarization/invoicing, etc.

  The security records are built so that only specific reader and writer accounts might
  access them.

  Data validation (consistency) is a function of the source database.

- User databases are databases accessible by a given user, who has "reader" rights only.
  A user's database's name is stored in that user's "_users" record as "user_database".
  It is freely accessible from an authenticated client, which locates it by querying for
  the user's profile data.
  The user's profile data is replicated from the _users database into the user database.

  User changes are processed and validated in the user database first (although these tests
  should be minimalist; proper validation and authorization can validly only be handled in
  the source databases).
  User changes are replicated back into the main/source (provisioning) database via client
  triggers.

  Global changes are pulled into a user database from a source database using filters
  (provided by the source databases)
  so that users only have access to authorized information.
  Pull operation is triggered by the client.

  Users may also freely replicate to/from their own databases if they wish (within the
  constraints enforced by each application's design documents).

  The list of available applications is established by listing the design documents and
  querying a record or attachment in each of them which describes the application
  (à la package.json / commonjs).
  (FIXME Currently we use jquery.couch's method, which relies on the presence of an "index.html" attachment to identify applications.)

  Applications are replicated from the source database "usercode" which contains all the
  available applications.
  All the data required by each application should be replicated into the user database
  so that these can be used offline / mobile.


- A user may have access to one or more account prefixes which are used to authorize
  operations.

  For example if an account is "ProviderA/ResellerB/CustomerC" then a prefix of
  "ProviderA/ResellerB/" would give access to that account (and others that share the same
  prefix).

- Individual operations are allowed based on the _users' standard "roles" array, using the format
  operation:database:account_prefix; for example:

    [ 'access:provisioning:ProviderA/ResellerB/', 'update:provisioning:ProviderA/ResellerB/CustomerC' ]

- Replication of data from the source databases into the user databases:

  Each source database provides an outgoing filter for replication towards user databases.
  That filter is named "user_pull" in the "replicate" design document.
  That filter is called (using a priviledged/admin account) with a request body "ctx" parameter
  that contains information required to authorize the replication, such as:
    name: the user's name (as defined in _users)
    roles: the roles defined for the user requesting the replication
  (this should be somewhat similar to a userCtx record, essentially).

- Replication of data from the user databases into the source databases:

  Data authorization is enforced at replication time by a dedicated filter, replicated from
  the usercode source database, and requested by the replication agent.
  Each design document is named after the source database it represents; the filter is named
  "user_pull" in that design document.

  Since the user might not modify design documents (they are not admins on their own databases),
  the presence of the design documents is enforced at replication time by requesting the proper
  replication filter from each application on the user database.

- Recommended code layout:

  ~source/couchapps/main        source database couchapp
  ~source/couchapps/usercode    user database couchapp

  The source database couchapp is pushed directly into the appropriate source database.
  The user database couchapp is pushed into the "usercode" source database.
  The user database couchapp is replicated by the client application.
