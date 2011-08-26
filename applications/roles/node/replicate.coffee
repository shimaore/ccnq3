# Although the replicator would allow the end-users to start replicating, since the source database is not accessible to them, they will (should) not be able to replicate from it.
# However the design rules inside the user's database enforce data consistency (and policies), so we can replicate from it without having to check per-user information in the main database.
# Conversely, we can replicate from the source database using a simple filter.

# Start replication from user's database back to a main database.

using 'json_req'

put '/replicate/push/:target': ->
  if not session.logged_in?
    return send error:'Not logged in.'

  # The only database we can push to is 'provisioning'.
  return send error:'Invalid target' unless @target in ['provisioning']

  replication_req =
    method: 'POST'
    uri: config.users.replicate_uri
    body:
      source: session.user_database
      target: @target

  json_req.request replication_req, (r) ->
    send r

# Start replication from a main database to the user's database
put '/replicate/pull/:source': ->
  if not session.logged_in?
    return send error:'Not logged in.'

  return send error:'Invalid source' unless @source in ['provisioning','billing']

  for role in session.roles
    do (role) ->
      prefix = role.match("^access:#{@source}:(.*)$")?[1]
      if prefix?

        replication_req =
          method: 'POST'
          uri: config.users.replicate_uri
          body:
            source: @source
            target: session.user_database
            filter: 'user_replication'
            query_params:
              prefix: prefix

        json_req.request replication_req, (r) ->
          send r
