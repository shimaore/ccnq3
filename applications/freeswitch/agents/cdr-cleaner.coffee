
## After CDRs are copied over from the local database, found in
# `config.cdr_uri ? http://127.0.0.1:5984/cdr`, into the central database,
# found in `cdr_aggregate_uri`, we purge the local records.

# We check every N minutes for changes, compare with the central database,
# and remove from the local database if found centrally.
#
# A minute is 60000 milliseconds
minute = 60*1000
# Default cleanup interval
default_cleanup_interval = 17*minute
default_bulk_size = 10000

# Note: we do not perform a revision check. CDRs are normally generated
# once and not modified. We only check whether if an ID exist on the local
# database, it also exists on the central database.
pico = require 'pico'
qs = require 'querystring'
util = require 'util'

run = (config) ->
  local_uri = config.cdr_uri
  if not local_uri?
    console.log "cdr-cleaner: no cdr_uri, skipping"
    return


  # Before doing any checks, ensure we are actually replicating.
  central_uri = config.cdr_aggregate_uri
  if not central_uri?
    console.log "Not replicating, skipping"
    return

  local = pico.request local_uri
  central = pico.request central_uri

  # Attempt to retrieve the last checkpoint, i.e. the last sequence
  # in the local database that we were able to validate in the central
  # database and then remove in the local database.
  checkpoint_path = "_local/cdr-cleanup-checkpoint"
  local.get checkpoint_path, json:true, (e,r,ck) ->
    ck ?= {}
    if e or not ck.checkpoint?
      last_checkpoint = 1
    else
      last_checkpoint = ck.checkpoint

    # Retrieve local changes since the last checkpoint, and try to locate them
    # in the central database.
    bulk_size = config.cdr_cleanup_size ? default_bulk_size
    local.get "_changes?since=#{last_checkpoint}&limit=#{bulk_size}", json:true, (e,r,b) ->
      if e or not b.results
        console.log "Getting _changes failed"
        return

      # b.results is an array of {seq,id,changes:[{rev}]}
      # Only keep CDRs
      keys = (r.id for r in b.results when r.id[0] isnt '_')

      # Attempt to locate our local changes in the central database.
      central.post '_all_docs', json:{keys}, (e,r,b) ->
        if e?
          console.log "Error: #{e}"
          return

        # The rows should be returned in the same order at the keys.
        if b.rows?
          # Build a bulk-delete document using the information found in the
          # central database.
          docs = []
          i = 0

          # We stop as soon as a document is missing, so that we can keep
          # data in `keys` aligned all the way to the end.
          while i < b.rows.length and b.rows[i].id?
            # If found, "id" will be present, along with "value", which
            # contains {rev}.
            # If deleted, "value" will also contain {deleted}.
            # If not found "error" will be present.
            # In all cases, "key" is present.
            row = b.rows[i]
            # The following line will do a bulk-delete, i.e. a job similar to
            #   local.del "#{qs.escape row.id}?rev=#{qs.escape row.value.rev}"
            # over a large number of records.
            docs[i] = _id:row.id, _rev:row.value.rev, _deleted:true
            i++

          local.post '_bulk_docs', json:{docs}, (e,r,b) ->
            if e? or not b?
              console.log "Failed to run bulk update"
              return
            for row, i in b
              if b.error or i is b.length-1
                # When we fail we save the new checkpoint
                # When we're done we save the new checkpoint

                # The following line is why `keys`, `docs`, and the
                # output of `_bulk_docs` must all be indexed the same.
                ck.checkpoint = keys[i].seq
                local.put checkpoint_path, json:ck, (e,r,b) ->
                  if e? or not b.ok
                    console.log """
                      Failed to save the new checkpoint: #{util.inspect b}
                    """
            return

require('ccnq3').config (config) ->
  do_run = -> run config
  setInterval do_run, config.cdr_cleanup_interval ? default_cleanup_interval
