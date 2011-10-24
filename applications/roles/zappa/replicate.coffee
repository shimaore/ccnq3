@include = ->

  config = null
  require('ccnq3_config').get (c) ->
    config = c

  # Start replication from user's database back to a main database.
  @post '/roles/replicate/push/:target': ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    # Validate the target name format.
    # Note: this does not allow all the possible names allowed by CouchDB.
    target = @params.target
    if not target.match /^[_a-z]+$/
      return @send error:'Invalid target'

    ctx =
      name: @session.logged_in
      roles: @session.roles

    replication_req =
      method: 'POST'
      uri: config.users.replicate_uri
      body:
        source: @session.user_database
        target: target
        filter: "#{target}/user_push" # Found in the userdb
        query_params:
          ctx: JSON.stringify ctx

    # Note: This will fail if the user database does not contain
    #       the proper design document for the specified target,
    #       so that restrictions are enforced.
    json_req = require 'json_req'
    json_req.request replication_req, (r) =>
      @send r

  # Start replication from a main database to the user's database
  @post '/roles/replicate/pull/:source': ->
    if not @session.logged_in?
      return @send error:'Not logged in.'

    # Validate the source name format.
    # Note: this does not allow all the possible names allowed by CouchDB.
    source = @params.source
    if not source.match /^[_a-z]+$/
      return @send error:'Invalid source'

    ctx =
      name: @session.logged_in
      roles: @session.roles

    replication_req =
      method: 'POST'
      uri: config.users.replicate_uri
      body:
        source: source
        target: @session.user_database
        filter: "replicate/user_pull" # Found in the source db
        query_params:
          ctx: JSON.stringify ctx

    # Note: The source replicate/user_pull filter is responsible for
    #       enforcing access restrictions.
    json_req = require 'json_req'
    json_req.request replication_req, (r) =>
      @send r
